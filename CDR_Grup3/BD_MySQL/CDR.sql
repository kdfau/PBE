# Base de dades CDR, PBE 
# Authors: Group 3; Adria, Iker, Queralt, Youssef
# Date: 28/04/2021

drop database if exists bd_CDR;
create database bd_CDR;
use bd_CDR;

--
-- Es creen les taules on es guarden les dades
--
CREATE  TABLE  Tasks (					
  dataEntrega DATE NOT NULL, -- Data d'entrega del treball					
  assignatura VARCHAR(15) NOT NULL,	-- Inicials de la asignatura					
  nomTreball VARCHAR(30) NOT NULL -- Nom del treball		
);

 CREATE  TABLE  Timetables (					
  dia VARCHAR(9) NOT NULL, -- Dia de la setmana					
  hora TIME NOT NULL,	-- Hora del dia					
  assignatura VARCHAR(15) NOT NULL, -- Inicials de la asignatura
  aula VARCHAR(8) -- Nom de l'aula (ex. A4-001) 
);

CREATE  TABLE  Marks (					
  assignatura VARCHAR(15) NOT NULL, -- Inicials de la asignatura				
  nomTreball VARCHAR(30) NOT NULL, -- Nom del treball
  nota FLOAT,	-- Nota obtinguda en el treball	
  uid VARCHAR(8) NOT NULL -- UID de l'usuari  FOREIGN KEY?
);

CREATE  TABLE  Students (					
  uid VARCHAR(8) NOT NULL, -- UID de l'usuari				
  nom VARCHAR(30)	
);

--
-- S'emplenen les taules amb valors predefinits desde els excels .csv
-- 

LOAD DATA INFILE 'C:\\Users\\adria\\Desktop\\UPC\\ETSETB\\3A\\PBE\\Practiques\\CDR\\CDR_MySQL\\Dades_Tasks.csv' 
	INTO TABLE Tasks 
	FIELDS TERMINATED BY ';' 
	OPTIONALLY ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 0 ROWS;

LOAD DATA INFILE 'C:\\Users\\adria\\Desktop\\UPC\\ETSETB\\3A\\PBE\\Practiques\\CDR\\CDR_MySQL\\Dades_Timetables.csv' 
	INTO TABLE Timetables 
	FIELDS TERMINATED BY ';' 
	OPTIONALLY ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 0 ROWS;
    
LOAD DATA INFILE 'C:\\Users\\adria\\Desktop\\UPC\\ETSETB\\3A\\PBE\\Practiques\\CDR\\CDR_MySQL\\Dades_Students.csv' 
	INTO TABLE Students 
	FIELDS TERMINATED BY ';' 
	OPTIONALLY ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 0 ROWS;
    
LOAD DATA INFILE 'C:\\Users\\adria\\Desktop\\UPC\\ETSETB\\3A\\PBE\\Practiques\\CDR\\CDR_MySQL\\Dades_Marks.csv' 
	INTO TABLE Marks 
	FIELDS TERMINATED BY ';' 
	OPTIONALLY ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 0 ROWS;

--
-- S'editen les taules per estructurar-les millor i crear relacions (foreign key) entre elles
--

ALTER TABLE Tasks
	ADD primary key(dataEntrega, assignatura, nomTreball);   -- Es podria fer sense data, pero així s'ordena bé directament
    
ALTER TABLE Timetables
	ADD primary key(dia,hora);   
    
ALTER TABLE Students
	ADD primary key(uid);     

ALTER TABLE Marks
	ADD primary key(uid,nomTreball),  
	ADD foreign key(uid)
	REFERENCES Students(uid);








