var http = require('http');
var url = require('url');

var urlq; 
var idTable; // Indica a quiena taula s'ha fet el query
var uid; // Uid usuari
var uid_aux; // Variable auxiliar per ajudar a identificar usuari correctament

// Es crea el servidor
http.createServer(function(req, res) {
    console.log('+++ Receving request...');
    urlq = url.parse(req.url, true);
    urlParams = new URLSearchParams(urlq.path);
    var callback = function(err, result) {
        res.writeHead(200, {'Content-Type' : 'text/json' });
        //console.log(url.parse(req.url, true));
        var t = urlq.query
        //console.log('json:', result);
        res.end(result);
    };
    getSQL(callback);  
}).listen(80);

// Es donen les dades de la BD a conectar-se
function getSQL(callback) {
    var mysql = require('mysql');
    var connection = mysql.createConnection({
        host : '127.0.0.1',
        user : 'root',
        password : 'rootmysql',
        database : 'bd_CDR',
    });

    // Es connecta a la BD
    connection.connect();

    //Es fa una consulta (query) a la BD i es retorna el json en el format adient pel client
    connection.query(querystring(), function(err, results, fields) {
        if (err)return callback(err, null);
        var output='';
        results.forEach(result =>{
            var text = JSON.parse(JSON.stringify(result));
            // Cambia el format del json depenent de quina taula s'ha consultat
            switch(idTable){
                case(0):
                    output += '["' +text.dia + '","' +text.hora+ '","' +text.assignatura+ '","' +text.aula+ '"]';
                break;
                case(1):
                    output += '["' +text.dataEntrega + '","' +text.assignatura+ '","' +text.nomTreball+ '"]';
                break;
                case(2):
                    output += '["' +text.assignatura + '","' +text.nomTreball+ '","' +text.nota+ '"]';
                break;
                case(3):
                    output += '["' +text.nom + '"]';
                break;
            }
            console.log(output);
        });
        
        // Comproba si l'usuari esta ben identificat
        if(output ==='' && uid === ""){
            output = '["User not found, try again"]';
        } else {
            uid = uid_aux;
        }

        connection.end();
        callback(null, output); // Es retorna al client la resposta a la seva query
    });  
};

// Funció que tradueix la query donada pel client en format MySQL
function querystring(){

    var table = 'SELECT * FROM ';
    var aux = urlq.path.split("/");

    // Comproba si la query te restriccion o no
    if(urlq.path.indexOf('?')>0){

        aux = aux[1].split("?");
        table += aux[0];
        var restriccio = false;

        // Per cada taula, es mira si es donen les possibles resticcions que cada taula ofereix
        switch(aux[0]){
            case('timetables'):
                
                idTable=0;
                var dia = getParameterByName('day');
                var hora = getParameterByName('hour');
                var assignatura = urlq.query.subject;
                var aula = urlq.query.room;

                if ( dia !== 'undefined' && dia ){
                    if(!restriccio){
                        table += ' WHERE dia '+gtolt('day')+' "' +dia+ '"';
                        restriccio = true;
                    }
                    else{
                        table += ' and dia '+gtolt('day')+' "' +dia+ '"';
                    }
                }

                if ( hora !== 'undefined' && hora ){
                    if(!restriccio){
                        table += ' WHERE hora '+gtolt('hour')+' "' +hora+ '"';
                        restriccio = true;
                    }
                    else{
                        table += ' and hora '+gtolt('hour')+' "' +hora+ '"';
                    }
                }

                if ( assignatura !== 'undefined' && assignatura ){
                    if(!restriccio){
                        table += ' WHERE assignatura = "' +assignatura +'"';
                        restriccio = true;
                    }
                    else{
                        table += ' and assignatura = "' +assignatura + '"';
                    }
                }

                if ( typeof aula !== 'undefined' && aula ){
                    if(!restriccio){
                        table += ' WHERE aula = "' +aula+ '"';
                        restriccio = true;
                    }
                    else{
                        table += ' and aula = "' +aula+ '"';
                    }
                }
            break;

            case('tasks'):

                idTable=1;
                var dataEntrega = getParameterByName('date');
                var nomTreball = urlq.query.name;
                var assignatura = urlq.query.subject;

                if ( dataEntrega!== 'undefined' && dataEntrega ){
                    if(!restriccio){
                        table += ' WHERE dataEntrega '+gtolt('date')+' "' +dataEntrega+ '"';
                        restriccio = true;
                    }
                    else{
                        table += ' and dataEntrega '+gtolt('date')+' "' +dataEntrega+ '"';
                    }
                }

                if ( nomTreball !== 'undefined' && nomTreball ){
                    if(!restriccio){
                        table += ' WHERE nomTreball = "' +nomTreball+ '"';
                        restriccio = true;
                    }
                    else{
                        table += ' and nomTreball = "' +nomTreball+ '"';
                    }
                }

                if ( assignatura !== 'undefined' && assignatura ){
                    if(!restriccio){
                        table += ' WHERE assignatura = "' +assignatura +'"';
                        restriccio = true;
                    }
                    else{
                        table += ' and assignatura = "' +assignatura + '"';
                    }
                }
            break;
               
            case('marks'): 

                idTable=2;
                var nota = getParameterByName('mark');
                var nomTreball = urlq.query.name;
                var assignatura = urlq.query.subject;
                table = 'SELECT nota, nomTreball, assignatura FROM marks';

                if ( nota!== 'undefined' && nota ){
                    if(!restriccio){
                        table += ' WHERE nota '+gtolt('mark')+' '+nota;
                        restriccio = true;
                    }
                    else{
                        table += ' and nota '+gtolt('mark')+' "' +nota+ '"';
                    }
                }

                if ( nomTreball !== 'undefined' && nomTreball ){
                    if(!restriccio){
                        table += ' WHERE nomTreball = "' +nomTreball+ '"';
                        restriccio = true;
                    }
                    else{
                        table += ' and nomTreball = "' +nomTreball+ '"';
                    }
                }

                if ( assignatura !== 'undefined' && assignatura ){
                    if(!restriccio){
                        table += ' WHERE assignatura = "' +assignatura +'"';
                        restriccio = true;
                    }
                    else{
                        table += ' and assignatura = "' +assignatura + '"';
                    }
                }
                
                if(restriccio){
                    table += ' AND uid = "' +uid+ '"';
                }else{
                    table += ' WHERE uid = "' +uid+ '"';
                }
            break;
            
            case('students'):
                idTable=3;
                uid="";
                uid_aux=urlq.query.uid;
                table = 'SELECT nom FROM students WHERE uid = "' +uid_aux+ '"';
            break;
        }

        var limit = urlq.query.limit;
        if ( limit !== 'undefined' && limit ){
            //do stuff if query is defined and not null
            table +=' LIMIT ' +limit;
        }
    
    // Cas en que no s'han especificat restriccions
    }else{
        switch(aux[1]){
            case('timetables'):
                idTable=0;
                table += aux[1] + ' WHERE hora >= now()';
            break;

            case('tasks'):
                idTable=1;
                table += aux[1] + ' ORDER BY dataEntrega ASC';
            break;
               
            case('marks'): 
                idTable=2;
                table = 'SELECT assignatura, nomTreball, nota FROM marks WHERE uid = "' +uid+ '" ORDER BY assignatura ASC';
            break;

        }
    }
    console.log(table);
    return table;
}


function gtolt(valor){
    var equal, num;
    if(urlq.path.indexOf(valor+'[gte]')>0){
        equal = ">="
    } else if (urlq.path.indexOf(valor+'[gt]')>0){
        equal = ">";
    } else if (urlq.path.indexOf(valor+'[lte]')>0){
        equal = "<=";
    } else if (urlq.path.indexOf(valor+'[lt]')>0){
        equal = "<";
    } else {
        equal = "=";
    }
    return equal;
}


function getParameterByName(name, url = urlq.path) {
    if(urlq.path.indexOf(name+'[gte]')>0){
        name+='[gte]';
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');

    } else if (urlq.path.indexOf(name+'[gt]')>0){
        name+='[gt]';
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');

    } else if (urlq.path.indexOf(name+'[lte]')>0){
        name+='[lte]';
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');

    } else if (urlq.path.indexOf(name+'[lt]')>0){
        name+='[lt]';
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');
  
    } else {
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)');
    }
    
    results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';

    return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

/*function simplificarResposta(input){
    var output="", comillas=0;
    for(var dosPunts=input.indexOf(":"); dosPunts!=-1; dosPunts=input.indexOf(":",comillas)){
        comillas=input.indexOf('"', dosPunts+2);
        output += input.substring(dosPunts+2, comillas)+" ";
    }
    return output;
}*/