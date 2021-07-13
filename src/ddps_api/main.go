package main

import (
	"database/sql"
	"flag"
	"fmt"
	_ "github.com/lib/pq"
	"log"
	"log/syslog"
	"net/http"
	"os"
	"os/signal"
	"path"
	"strconv"
	"time"
)

var debug bool
var printversion bool
var token_expiration_time int
var myname string

var conf File
var sleeptime int // sleep time between unsuccessful db connection attempts
var err error
var db *sql.DB
var tmpstr string

func init() {
	sleeptime = 2

	flag.BoolVar(&debug, "v", false, "log verbose will reveal passwords")
	flag.BoolVar(&printversion, "V", false, "Print version and exit")
	inifile := flag.String("f", "/opt/db2bgp/etc/ddps.ini", "Use `file.ini` as configuration file")

	_, myname = path.Split(os.Args[0])
	flag.Usage = func() {
		fmt.Printf("\n%s [-V] [-v] [-f config]\n\n", myname)

		flag.PrintDefaults()
	}
	flag.Parse()

	if printversion {
		fmt.Printf("Version              '%s'\n", version)
		fmt.Printf("Build date           '%s'\n", build_date)
		fmt.Printf("build_git_sha        '%s'\n", build_git_sha)

		os.Exit(1)
	}

	conf, err = LoadFile(*inifile)

	Logwriter, e := syslog.New(syslog.LOG_NOTICE, "ddps_api")
	if e == nil {
		log.SetOutput(Logwriter)
	}
	log.Print("program '", myname, "' starting, parameters: debug: '", debug, "', token_expiration_time: '", token_expiration_time, "'", " inifile: '", *inifile, "'")

	/*
	 *  check required parameters for postgres connection
	 */
	dbtuple := []string{"dbname", "dbuser", "dbpassword", "dbhost", "API_ListenAddressAndPort"}
	for _, element := range dbtuple {
		_, ok := conf.Get("general", element)
		if !ok {
			fmt.Println("variable '", element, "' missing from 'general' section")
			log.Printf("'%s' variable missing from 'general' section\n", element)
			os.Exit(1)
		}
	}

	dbhost, _ := conf.Get("general", "dbhost")
	tmpstr, _ := conf.Get("general", "dbport")
	dbport, _ := strconv.Atoi(tmpstr)
	dbname, _ := conf.Get("general", "dbname")
	dbuser, _ := conf.Get("general", "dbuser")
	dbpassword, _ := conf.Get("general", "dbpassword")
	tmpstr, _ = conf.Get("general", "token_expiration_time")
	token_expiration_time, _ = strconv.Atoi(tmpstr)

	for {
		if debug {
			log.Print("DEBUG: connection string: host: '", dbhost, "', port '", dbport, "', password '", dbpassword, "',  dbname '", dbname, "', sslmode disabled")
		} else {
			log.Print("postgres connection string: host: '", dbhost, "', port '", dbport, "', password 'XXXXXXXX',  dbname '", dbname, "', sslmode disabled")
		}

		psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", dbhost, dbport, dbuser, dbpassword, dbname)
		db, err = sql.Open("postgres", psqlInfo)
		if err != nil {
			log.Print("WARNING: connection failed, sleeping ", sleeptime, " seconds: err: ", err)
		}

		err = db.Ping()
		if err != nil {
			log.Print("WARNING: connection unsuccessful, db.Ping failed: err: ", err)
			time.Sleep(time.Duration(sleeptime) * time.Second)
		} else {
			log.Print("SUCCESS: connection successful and db.Ping ok")
			break
		}
	}
	log.Print("connected to postgres database '", dbname, "' as user '", dbuser, "'")
}

func main() {
	/* handle graceful shotdown via signals */
	// setup signal catching
	sigs := make(chan os.Signal, 1)

	// catch all signals since not explicitly listing
	signal.Notify(sigs)
	//signal.Notify(sigs,syscall.SIGQUIT)

	// method invoked upon seeing signal
	go func() {
		s := <-sigs
		log.Printf("RECEIVED SIGNAL: %s", s)
		AppCleanup()
		os.Exit(1)
	}()

	// "Signin" and "Addrule" are the handlers that we will implement
	http.HandleFunc("/signin", Signin)
	http.HandleFunc("/addrule", Addrule)
	http.HandleFunc("/refresh", Refresh)

	// log.Fatal(http.ListenAndServe("192.168.33.12:8888", nil))
	API_ListenAddressAndPort, _ := conf.Get("general", "API_ListenAddressAndPort")
	log.Fatal(http.ListenAndServe(API_ListenAddressAndPort, nil))

	defer db.Close()
}

func check(e error) {
	if e != nil {
		fmt.Println("configuration error: %s \n", e)
		log.Printf("configuration error:", e)
		os.Exit(1)
	}
}

func AppCleanup() {
	log.Print("TODO: CLEANUP APP BEFORE EXIT!!!")
}

/*
 * Hmm pg seems depricated, new projects should use pgx, but
 * https://medium.com/avitotech/how-to-work-with-postgres-in-go-bad2dabd13e4 is
 * a bit more demanding so I think pg is ok for now
 */

/* written by NTH, 2021, see LICENSE */
