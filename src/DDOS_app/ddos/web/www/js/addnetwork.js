 $(document).ready(function() {
    $("#addnetwork").submit(function(e){
        var dstVal = $("#dstaddress").val();
        dstVal = dstVal.trim();
        if (dstVal){
            var flag=validateCidr(dstVal);
                var matched=false;
                if (flag==false) {
                    //alert("Invalid CIDR");
                    Swal.fire({
                        icon: 'error',
                        title: 'Error...',
                        text: 'Invalid CIDR!'
                    })
                    e.preventDefault();
                }else{
                    $("#chkdstadress > option").each(function() {
                        if (dstVal == this.value) {
                            matched=true;
                        } else {
                            var chk=inSubNet(dstVal, this.value);
                            if (chk==true){
                                matched=true;
                            }
                        }
                    });
                    if (matched==false){
                        //alert('You do not have permissions for creating rules for the destination CIDR; it is not part of or a subnet of your assigned networks.');
                        Swal.fire({
                            icon: 'error',
                            title: 'Error...',
                            text: 'You do not have permissions to add Network outside of your assigned networks.!'
                        })
                        e.preventDefault();
                    }else{
                        //alert("Matched");
                    }
                }
         }
   });

});

function validateCidr(cidr){
    var temp = new RegExp('^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$');
    var flag = temp.test(cidr);
    return flag;
}

var ip2long = function(ip){
    var components;
    if(components = ip.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)){
        var iplong = 0;
        var power  = 1;
        for(var i=4; i>=1; i-=1){
            iplong += power * parseInt(components[i]);
            power  *= 256;
        }
        return iplong;
    }else{
        return -1;
    }
};

var inSubNet = function(ip, subnet)
{
    temp=ip.split("/");
    temp2=subnet.split("/");

    var mask, base_ip, long_ip = ip2long(temp[0]);
    if( (mask = subnet.match(/^(.*?)\/(\d{1,2})$/)) && ((base_ip=ip2long(mask[1])) >= 0) && temp[1]>temp2[1]){
        var freedom = Math.pow(2, 32 - parseInt(mask[2]));
        return (long_ip > base_ip) && (long_ip < base_ip + freedom - 1);
    }else{
        return false;
    }
};