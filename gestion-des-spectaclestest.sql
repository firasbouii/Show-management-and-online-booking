select * from lieu;
select * from spectacle;
select * from artiste;
select * from rubrique;
/********************regle d'integrité*******************************/
insert into client values(SEQCLIENT.nextval,'ksouri','chahd','258963','chahd@gmail.com','147852369');   
insert into lieu values(17,'cinema ABC','centre ville',2001);
/*********************ajouter,recherche user*****************/
SET SERVEROUTPUT ON 
EXECUTE gest_util.ajout_user('admin1','123456');
EXECUTE gest_util.modifier_user('admin1','654321');
EXECUTE gest_util.recherche_user('adminBD');
SELECT *   FROM DBA_ROLE_PRIVS  where grantee like upper('Planificateurevt');
/**********************ajouter spectacle********************/
set serveroutput on
execute ajout_spec('24 odeurs','31/01/2021',19,3,1500,16);
/**************************annuler spectacle*****************************/
execute annul_spec(8);
/*******************modifier le titre du spectacle****************/
DECLARE 
    BEGIN
    modif_titre(9,'Melouf');
    END;

/****************modifier date ********************/
 DECLARE 
    BEGIN
    modif_date(9,'27/01/2021');     
    END; 
/*********************modifier heure de debut*******************/
DECLARE
BEGIN 
modif_heure_debut(8,16);
END;
/****************trigger_after_modif_duree_s*********************/
CREATE OR REPLACE  TRIGGER trigger_after_modif_duree_s
AFTER UPDATE   
OF DUREES  
ON spectacle  
FOR EACH ROW     
DECLARE 
   difference  spectacle.DUREES%TYPE;
   idrubrique rubrique.IDRUB%TYPE;
   nb_rubriques int ;
   dur spectacle.DUREES%TYPE;
   CURSOR cur  IS 
        SELECT IDRUB,DUREERUB 
        FROM rubrique
        WHERE idspec=:NEW.idspec;
BEGIN  
	difference := :NEW.DUREES - :old.DUREES;
	select count(IDRUB)
   into nb_rubriques
   from rubrique
   where idspec=:NEW.idspec;
   OPEN cur;
   LOOP
   FETCH cur INTO idrubrique,dur;
   EXIT	WHEN	NOT	cur%FOUND;	
   dbms_output.put_line( idrubrique );
   update rubrique set DUREERUB = :NEW.DUREES -1 / nb_rubriques where idspec=:NEW.idspec and IDRUB = idrubrique;
END LOOP; 
END; 
/********************modifier duree du spectacle********************/
DECLARE
BEGIN 
modif_duree(13,4);
END;
/*******************trg_check_nbr_spectateur***********************/
 CREATE OR REPLACE TRIGGER trg_check_nbr_spectateur
  BEFORE UPDATE ON spectacle
  FOR EACH ROW
  DECLARE 
  vid_lieu SPECTACLE.IDLIEU%TYPE ;
  vcap Lieu.capacite%TYPE ;
BEGIN
	select CAPACITE into vcap 
	from  lieu 
	where idlieu=:NEW.IDLIEU;
  IF  :NEW.nbrSpectateur > vcap then 
            RAISE_APPLICATION_ERROR(-20104,'capacite de lieu insuffisante pr ce  nombre de spectateurs!');
  END IF;
  END;
/**************modifier nbr de spectateurs******************/
  DECLARE 
    BEGIN
    modif_spectateur(14,1200);
    END; 
/****************modifier lieu******************/
    DECLARE 
    BEGIN
    modif_lieu(9,7);
    END;
/****************recherche si rubrique exist********************/
    DECLARE 
    t BOOLEAN;
BEGIN
    t := rechercher_rub_idspec(13);
    IF t THEN
        dbms_output.put_line('oui il existe une rubrique pour id spec');
    ELSE
        dbms_output.put_line('non pas de rubrique pourr id spec !!');   
    END IF;
END;

/****************trigger_modif_heure_debut_rub*******************/
CREATE OR REPLACE  TRIGGER trigger_modif_heure_debut_rub
BEFORE update of H_DEBUTR
ON RUBRIQUE
FOR EACH ROW        
DECLARE
    V_H_DEBUT spectacle.H_DEBUT%TYPE;
    v_durees spectacle.durees%type;
BEGIN
    SELECT H_DEBUT,durees+H_DEBUT INTO V_H_DEBUT,v_durees  FROM spectacle WHERE IDSPEC= :NEW.IDSPEC;    
     IF   ( V_H_DEBUT < :NEW.H_DEBUTR ) and ( :NEW.H_DEBUTR+:old.dureerub <= v_durees) then 
            dbms_output.put_line('l heure de debut de rubrique  par rapport a celle du spectacle verifié !');
        ELSE 
            RAISE_APPLICATION_ERROR(-20520,'erreur !! une rubrique ne commence pas avant le spectacle');
        END IF;
        END; 
/******************modif rubrique****************/
set serveroutput on
execute modif_rubrique.modif_duree(15,2);
execute modif_rubrique.modif_artiste(15,4);
execute modif_rubrique.modif_heure_debut(16,20);     
/*************supprimer rubrique**************/
set serveroutput on
execute supprimer_rub(15);
