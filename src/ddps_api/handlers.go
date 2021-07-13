package main

/*
* ERROR: program error(s)
* SUCCESS: ignore
* WARNING: alarm to be catched by fail2ban
 */

/*
	TODO / STATUS:

	 - [x] jwt token ok
	 - [x] sets uuid in jwt correctly / returns administrator and customer id
	 - [x] routers ready sending errors/warnings to syslog for fail2ban
	 - [x] addrule prints all parameters correctly
	 - [-] addrule verification of field type tested
	 - [x] parse / read ini file for db2bgp
	 - [x] connects to postgresql
	 - [x] login reads from postgresql
	 - [x] login handles errors from postgresql correctly
	 - [x] addrule writes to postgresql
	 - [x] addrule handles errors from postgresql correctly
	 - [ ] Write / fix some thing about the API and return values / strings:
		- If the json is not valid [json validator](https://jsonlint.com) then the reply string is not accurate
	 - [x] systemd start/stop
	 - [x] make install sort-of
	 - [ ] version 1.0-1 done
*/

import (
	"encoding/json"
	"fmt"
	"github.com/dgrijalva/jwt-go"
	_ "github.com/lib/pq"
	"gopkg.in/go-playground/validator.v9"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	//	"os"
	"strconv"
	"strings"
	"time"
)

/*  Assumes the following table layout:

    srcordestport character varying(128),
    destinationport character varying(128),
    sourceport character varying(128),
    icmptype character varying(128),
    icmpcode character varying(128),
    packetlength character varying(128),
    dscp character varying(128),
    fragmentencoding character varying(128),
    ipprotocol character varying(128),
    tcpflags character varying(128),

    description character varying(256),
    destinationprefix inet,
    sourceprefix inet,
    notification character varying,
    thenaction character varying, one of
		accept
		discard
		rate-limit 9600
		rate-limit 19200
		rate-limit 38400
*/

/* TODO: Validation
struct below doesn't walidate correctly: min/max is ignored search for
* below as I have no idea on how to do it better / more correctly
*/

type Rule struct {
	/* TODO: min, max should be read from config */
	Durationminutes   string `validate:"gte=0,lte=4"` // see later
	Sourceport        string `json:"sourceport", validate:"max=128"`
	Destinationport   string `json:"destinationport", validate:"max=128"`
	Icmptype          string `json:"icmptype", validate:"max=128"`
	Icmpcode          string `json:"icmpcode", validate:"max=128"`
	Packetlength      string `json:"packetlength", validate:"max=128"`
	Dscp              string `json:"dscp", validate:"max=128"`
	Description       string `json:"description"`
	Destinationprefix string `json:"destinationprefix"`
	Sourceprefix      string `json:"sourceprefix"`
	Thenaction        string `json:"thenaction"`
	Fragmentencoding  string `json:"fragmentencoding", validate:"max=128"`
	Ipprotocol        string `json:"ipprotocol", validate:"max=128"`
	Tcpflags          string `json:"tcpflags", validate:"max=128"`
}

/* Just for the record: case matters in go ... */

var validate *validator.Validate
var duration_int int64

/* TODO: to be read from config file */
var jwtKey = []byte("qQGc-$c@#-1gv#-DQa!-Q4!2-@awT-ZaqB-Z#AT-rtSz-vF%X-BfR5-#X!a")

type User struct {
	Username   string
	Password   string
	Adminid    string
	Customerid string
}

// Create a struct that models the structure of a user, both in the request body, and in the DB
type Credentials struct {
	Password string `json:"password"`
	Username string `json:"username"`
}

/* TODO: read from db */
type Claims struct {
	Username   string `json:"username"`
	Adminid    string // read from db
	Customerid string // read from db
	jwt.StandardClaims
}

func Signin(w http.ResponseWriter, r *http.Request) {

	client_ip := GetIP(r)

	requestDump, err := httputil.DumpRequest(r, true) /* httputil.DumpRequest is a debug function, ignore if it fails */
	if err != nil {
		log.Print("ERROR: httputil.DumpRequest failed: ", requestDump, " err: ", err)
	}

	// Get the JSON body and decode into credentials
	var creds Credentials
	err = json.NewDecoder(r.Body).Decode(&creds)
	defer r.Body.Close()

	if err != nil {
		// If the structure of the body is wrong, return an HTTP error
		if debug {
			log.Print("WARNING: /signin called but failed to parse body from", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("WARNING: /signin called but failed to parse body from", client_ip)
		}
		http.Error(w, "failed to parse JSON body", http.StatusBadRequest)
		return
	}

	// execute sql to validate credentials
	var signinUser User
	userSql := fmt.Sprintf("SELECT * from public.ddps_login('%s', '%s')", creds.Username, creds.Password)

	err = db.QueryRow(userSql).Scan(&signinUser.Adminid, &signinUser.Customerid)
	// TODO: sql.ErrNoRows <-- not found ??? would make code more readable
	if err != nil {
		if len(signinUser.Adminid) == 0 || len(signinUser.Customerid) == 0 {
			log.Print("WARNING: /signin called with invalid user '", creds.Username, "' or password '", creds.Password, "' from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("ERROR: failed to execute query: ", userSql, " error: ", err)
		}
		http.Error(w, "user / password is wrong or unknown", http.StatusUnauthorized)
		return
	} else {
		log.Print("SUCCESS: adminid = '", signinUser.Adminid, "', Customerid = '", signinUser.Customerid, "'")
	}

	/* Declare the expiration time of the token to 10 minutes */
	expirationTime := time.Now().Add(time.Duration(token_expiration_time) * time.Minute)

	/* Create the JWT claims, which includes the username and expiry time */
	claims := &Claims{
		Username:   creds.Username,
		Adminid:    signinUser.Adminid,
		Customerid: signinUser.Customerid,
		StandardClaims: jwt.StandardClaims{
			/* In JWT, the expiry time is expressed as unix milliseconds */
			ExpiresAt: expirationTime.Unix(),
		},
	}

	// Declare the token with the algorithm used for signing, and the claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	// Create the JWT string
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		// If there is an error in creating the JWT return an internal server error
		http.Error(w, "internal error creating token", http.StatusInternalServerError)
		if debug {
			log.Print("ERROR: /signin internal error creating JWT token ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("ERROR: /signin internal error creating JWT token ", client_ip)
		}
		return
	}

	// Finally, we set the client cookie for "token" as the JWT we just generated
	// we also set an expiry time which is the same as the token itself
	if debug {
		log.Print("SUCCES: /signin successful returning cookie to from ", client_ip, " dump: ", string(requestDump))
	} else {
		log.Print("SUCCES: /signin successful returning cookie to from ", client_ip)
	}
	http.SetCookie(w, &http.Cookie{
		Name:    "token",
		Value:   tokenString,
		Expires: expirationTime,
	})
}

func Addrule(w http.ResponseWriter, r *http.Request) {

	client_ip := GetIP(r)

	requestDump, err := httputil.DumpRequest(r, true)
	if err != nil {
		log.Print("ERROR: httputil.DumpRequest failed: ", requestDump, " err: ", err)
	}

	// We can obtain the session token from the requests cookies, which come with every request
	c, err := r.Cookie("token")
	if err != nil {
		if err == http.ErrNoCookie {
			// If the cookie is not set, return an unauthorized status
			if debug {
				log.Print("WARNING: /addrule called from ", client_ip, " but cookie not set from: ", client_ip, " dump: ", string(requestDump))
			} else {
				log.Print("WARNING: /addrule called from ", client_ip, " but cookie not set from: ", client_ip)
			}
			http.Error(w, "no cookie", http.StatusUnauthorized)
			return
		}
		// For any other type of error, return a bad request status
		http.Error(w, "other unaccounted error", http.StatusBadRequest)
		return
	}

	// Get the JWT string from the cookie
	tknStr := c.Value

	// Initialize a new instance of `Claims`
	claims := &Claims{}

	// Parse the JWT string and store the result in `claims`.
	// Note that we are passing the key in this method as well. This method will return an error
	// if the token is invalid (if it has expired according to the expiry time we set on sign in),
	// or if the signature does not match
	tkn, err := jwt.ParseWithClaims(tknStr, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})
	if err != nil {
		if err == jwt.ErrSignatureInvalid {
			http.Error(w, "invalid signature", http.StatusUnauthorized)
			if debug {
				log.Print("WARNING: /addrule called unauthorized from ", client_ip, " dump: ", string(requestDump))
			} else {
				log.Print("WARNING: /addrule called unauthorized from ", client_ip)
			}
			return
		}
		http.Error(w, "bad request", http.StatusBadRequest)
		if debug {
			log.Print("WARNING: /addrule called but StatusBadRequest from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("WARNING: /addrule called but StatusBadRequest from ", client_ip)
		}
		return
	}
	if !tkn.Valid {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		if debug {
			log.Print("WARNING: /addrule called token not vald from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("WARNING: /addrule called token not vald from ", client_ip)
		}
		return
	}
	/* no errors in token, continue with field validation */

	validate = validator.New()

	var rule Rule
	err = json.NewDecoder(r.Body).Decode(&rule)
	defer r.Body.Close()

	/* TODO:
	* Expeted validate.Struct(rule) to validate JSON, but tests shows that this is not the case
	* But I'll leave it for now as errors are catched later, just the error messages are then
	* not absolutely correct: ie no trailing ',' means the next key/value is reported wrong
	* Will look at https://stackoverflow.com/questions/56378317/how-to-validate-json-input
	 */

	err = validate.Struct(rule)
	if err != nil {
		if _, ok := err.(*validator.InvalidValidationError); ok {
			log.Println("WARNING: /addrule called from ", client_ip, " with faulty json: ", err)
		}
		for _, err := range err.(validator.ValidationErrors) {
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s): ", err)
		}
		http.Error(w, "json validation error", http.StatusUnauthorized)
		return
	} else {
		/* The following is just to ensure that the types matches the sql function
		*	But I have no idea why validation of json and validate doesn't work together
		 */
		is_valid := true

		var errstr []string
		errstr = append(errstr, "field validation / data type error(s):")

		// Test data types, a more thorough test is done in postgres
		if _, err := strconv.ParseInt(rule.Durationminutes, 10, 64); err == nil {
			duration_int, _ = strconv.ParseInt(rule.Durationminutes, 10, 64)
			if duration_int >= 0 && duration_int <= 1440 {
			} else {
				is_valid = false
				errstr = append(errstr, "durationminutes exceeds limits 0-1440,")
				log.Print("WARNING: /addrule called from ", client_ip, errstr, err)
			}
		} else {
			is_valid = false
			errstr = append(errstr, "durationminutes not a number,")
			log.Print("WARNING: /addrule called from ", client_ip, errstr, err)
		}

		err = validate.Var(rule.Sourceport, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of sourceport length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, errstr, err)
		}
		err = validate.Var(rule.Destinationport, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of destinationport length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, errstr, err)
		}
		err = validate.Var(rule.Icmptype, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of icmptype length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, errstr, err)
		}
		err = validate.Var(rule.Icmpcode, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of icmpcode length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, errstr, err)
		}
		err = validate.Var(rule.Packetlength, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of packetlength length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Packetlength", err)
		}
		err = validate.Var(rule.Dscp, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of dscp length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Dscp", err)
		}
		err = validate.Var(rule.Description, "min=0,max=256")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of description length exceeds 256 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Description", err)
		}

		if (rule.Destinationprefix) != "" {
			_, _, err = net.ParseCIDR(rule.Destinationprefix)
			if err != nil {
				is_valid = false
				errstr = append(errstr, "invalid destinationprefix,")
				log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Destinationprefix not valid: ", rule.Destinationprefix)
			}
		} else {
			is_valid = false
			errstr = append(errstr, "empty destinationprefix,")
			log.Print("WARNING: /addrule called from ", client_ip, " with empty Destinationprefix")
		}

		if (rule.Sourceprefix) != "" {
			_, _, err = net.ParseCIDR(rule.Sourceprefix)
			if err != nil {
				is_valid = false
				errstr = append(errstr, "invalid Sourceprefix,")
				log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Sourceprefix", err)
			}
		}
		err = validate.Var(rule.Thenaction, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of thenaction length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Thenaction", err)
		}
		err = validate.Var(rule.Fragmentencoding, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of Fragmentencoding length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Fragmentencoding", err)
		}
		err = validate.Var(rule.Ipprotocol, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of Ipprotocol length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Ipprotocol", err)
		}
		err = validate.Var(rule.Tcpflags, "min=0,max=128")
		if err != nil {
			is_valid = false
			errstr = append(errstr, "length of Tcpflags length exceeds 128 chars,")
			log.Print("WARNING: /addrule called from ", client_ip, " parameter error(s) Tcpflags", err)
		}

		rule_str_json := " rule: { \"administratorid \": " + claims.Adminid + "\"" +
			" \"customerid\" : \"" + claims.Customerid + "\"" +
			" \"Sourceport\" : \"" + rule.Sourceport + "\", " +
			" \"Durationminutes\" : \"" + rule.Durationminutes + "\", " +
			" \"Destinationport\" : \"" + rule.Destinationport + "\", " +
			" \"Icmptype\" : \"" + rule.Icmptype + "\", " +
			" \"Icmpcode\" : \"" + rule.Icmpcode + "\", " +
			" \"Packetlength\" : \"" + rule.Packetlength + "\", " +
			" \"Dscp\" : \"" + rule.Dscp + "\", " +
			" \"Description\" : \"" + rule.Description + "\", " +
			" \"Destinationprefix\" : \"" + rule.Destinationprefix + "\", " +
			" \"Sourceprefix\" : \"" + rule.Sourceprefix + "\", " +
			" \"Thenaction\" : \"" + rule.Thenaction + "\", " +
			" \"Fragmentencoding\" : \"" + rule.Fragmentencoding + "\", " +
			" \"Ipprotocol\" : \"" + rule.Ipprotocol + "\", " +
			" \"Tcpflags\" : \"" + rule.Tcpflags + "\"}\n"

		/* The SQL function takes a large number of arguments:
		*
		*	public.ddps_addrule (validfrom, validto, direction, srcordestport,
		*	destinationport, sourceport, icmptype, icmpcode, packetlength,
		*	dscp, description, uuid_customerid, uuid_administratorid,
		*	destinationprefix, sourceprefix, thenaction, fragmentencoding,
		*	ipprotocol, tcpflags)"
		* Buld an SQL expression for that, and define validfrom as now(),
		* validto as now() + duration. "direction" is always 'in' (at least for
		* now) while "srcordestport" is not used (at least for now) and from
		* the API
		* A note on time, since I don't have the reference any more:
		* time.Now().Local().Add(time.Hour * time.Duration(Hours) + time.Minute * time.Duration(Mins) + time.Second * time.Duration(Sec))
		* Not gnu date
		 */

		uuid_administratorid := claims.Adminid
		uuid_customerid := claims.Customerid

		validfrom := time.Now().Local()
		validto := time.Now().Local().Add(time.Minute * time.Duration(duration_int))
		direction := "in"
		srcordestport := ""

		rule_str_sql := fmt.Sprintf("SELECT * FROM public.ddps_addrule ('%s', '%s', '%s', '%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')",
			validfrom.Format("2006-01-02 15:04:05"), validto.Format("2006-01-02 15:04:05"),
			direction, srcordestport, rule.Destinationport, rule.Sourceport, rule.Icmptype,
			rule.Icmpcode, rule.Packetlength, rule.Dscp, rule.Description, uuid_customerid,
			uuid_administratorid, rule.Destinationprefix, rule.Sourceprefix, rule.Thenaction,
			rule.Fragmentencoding, rule.Ipprotocol, rule.Tcpflags)

		/* ddps_addrule returns true/false and raises an exception with an
		* error message, don't know it that was the best design */

		/* nothing wrong found on rule up to now but real scrutiny takes place in database function */
		if is_valid == true {
			/*  add rule to database and check the result. On error send one message, on succes an other */
			var sql_res string
			err = db.QueryRow(rule_str_sql).Scan(&sql_res)
			if err != nil {
				log.Print("WARNING: /Addrule adding rule '", rule_str_sql, "', failed. Err: '", err.Error(), "'")
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			} else {
				log.Print("SUCCESS: sql ok: ", rule_str_sql)
				log.Print("SUCCESS: /addrule called successfully from ", claims.Username, "@", client_ip, " rule: ", rule_str_sql)
				http.Error(w, "rule accepted", http.StatusOK)
			}
		} else {
			if debug {
				log.Print("WARNING: /addrule called with parameter errors from ",
					claims.Username, "@", client_ip, " rule: ", rule_str_json)
			}
			errstr = append(errstr, "rule discarded")
			tmpstr := strings.Join(errstr, " ")
			http.Error(w, tmpstr, http.StatusUnauthorized)
		}
	}
}

func Refresh(w http.ResponseWriter, r *http.Request) {

	requestDump, err := httputil.DumpRequest(r, true)
	if err != nil {
		log.Print("ERROR: httputil.DumpRequest failed: ", requestDump, " err: ", err)
	}

	client_ip := GetIP(r)
	c, err := r.Cookie("token")
	if err != nil {
		if err == http.ErrNoCookie {
			http.Error(w, "no cookie", http.StatusUnauthorized)
			if debug {
				log.Print("WARNING: /refresh called without valid cookie from ", client_ip, " dump: ", string(requestDump))
			} else {
				log.Print("WARNING: /refresh called without valid cookie from ", client_ip)
			}
			return
		}
		http.Error(w, "bad request", http.StatusBadRequest)
		if debug {
			log.Print("WARNING: /refresh called wit StatusBadRequest from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("WARNING: /refresh called wit StatusBadRequest from ", client_ip)
		}
		return
	}
	tknStr := c.Value
	claims := &Claims{}
	tkn, err := jwt.ParseWithClaims(tknStr, claims, func(token *jwt.Token) (interface{}, error) {
		if debug {
			log.Print("SUCCESS: /refresh new cookie to/from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("SUCCESS: /refresh new cookie to/from ", client_ip)
		}
		return jwtKey, nil
	})
	if !tkn.Valid {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		if debug {
			log.Print("WARNING: /refresh called without valid cookie from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("WARNING: /refresh called without valid cookie from ", client_ip)
		}
		return
	}
	if err != nil {
		if err == jwt.ErrSignatureInvalid {
			http.Error(w, "invalid signature", http.StatusUnauthorized)
			if debug {
				log.Print("WARNING: /refresh called with ErrSignatureInvalid from ", client_ip, " dump: ", string(requestDump))
			} else {
				log.Print("WARNING: /refresh called with ErrSignatureInvalid from ", client_ip)
			}
			return
		}
		http.Error(w, "bad request", http.StatusBadRequest)
		if debug {
			log.Print("WARNING: /refresh called with StatusBadRequest from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("WARNING: /refresh called with StatusBadRequest from ", client_ip)
		}
		return
	}
	// (END) The code uptil this point is the same as the first part of the `Welcome` route

	// We ensure that a new token is not issued until enough time has elapsed
	// In this case, a new token will only be issued if the old token is within
	// 30 seconds of expiry. Otherwise, return a bad request status
	if time.Unix(claims.ExpiresAt, 0).Sub(time.Now()) > 30*time.Second {
		http.Error(w, "token expired", http.StatusBadRequest)
		if debug {
			log.Print("WARNING: /refresh called after token time out from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("WARNING: /refresh called after token time out from ", client_ip)
		}
		return
	}

	// Now, create a new token for the current use, with a renewed expiration time
	expirationTime := time.Now().Add(5 * time.Minute)
	claims.ExpiresAt = expirationTime.Unix()
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		if debug {
			log.Print("ERROR: /refresh called StatusInternalServerError from ", client_ip, " dump: ", string(requestDump))
		} else {
			log.Print("ERROR: /refresh called StatusInternalServerError from ", client_ip)
		}
		return
	}

	// Set the new token as the users `session_token` cookie
	http.SetCookie(w, &http.Cookie{
		Name:    "session_token",
		Value:   tokenString,
		Expires: expirationTime,
	})
	if debug {
		log.Print("SUCCES: /refresh new token to/from ", client_ip, " dump: ", string(requestDump))
	} else {
		log.Print("SUCCES: /refresh new token to/from ", client_ip)
	}
}

// GetIP gets a requests IP address by reading off the forwarded-for
// header (for proxies) and falls back to use the remote address.
// Header.Get is case-insensitive
func GetIP(r *http.Request) string {
	forwarded := r.Header.Get("X-Forwarded-For")

	// Loop over header names if debug
	if debug {
		for name, values := range r.Header {
			// Loop over all values for the name.
			for _, value := range values {
				log.Print("GetIP header: ", name, " value: ", value)
			}
		}
	}
	// log.Print("GetIP: forwarded = '", forwarded, "' , r.RemoteAddr = '", r.RemoteAddr, "'")
	if forwarded != "" {
		return forwarded
	}
	return r.RemoteAddr
}

/* written by NTH, 2021, see LICENSE */
/*
 	https://www.calhoun.io/querying-for-a-single-record-using-gos-database-sql-package/
	https://www.calhoun.io/inserting-records-into-a-postgresql-database-with-gos-database-sql-package/
	https://github.com/lib/pq
	https://www.opsdash.com/blog/postgres-arrays-golang.html
	https://golangcode.com/postgresql-connect-and-query/
	https://stackoverflow.com/questions/51142255/querying-a-postgres-with-golang
	https://astaxie.gitbooks.io/build-web-application-with-golang/content/en/05.4.html
*/
