/*********pour valider si spectacle existe ou nn avant d'ajoute********************/
CREATE OR REPLACE FUNCTION  spec_valid (
    da   spectacle.dates%TYPE,
    hd   spectacle.h_debut%TYPE,
    d   spectacle.durees%TYPE,
    l    spectacle.idlieu%TYPE
) RETURN BOOLEAN AS
    v_id   spectacle.idspec%TYPE;
    v_hd   spectacle.h_debut%TYPE;
    v_d  spectacle.h_debut%TYPE;
    h_f    spectacle.h_debut%TYPE := hd + d ; -- hf = heure fin du spectacles  deja existants
    CURSOR cur_spec IS SELECT idspec, h_debut, h_debut + durees AS h_fin
    FROM spectacle
    WHERE dateS = da
    AND idlieu = l
    AND ( hd BETWEEN  h_debut AND   h_debut + durees  AND  hd NOT IN (h_debut+durees) 
            OR            
          h_f BETWEEN  h_debut AND   h_debut + durees  AND  h_f NOT IN (h_debut )       
            OR 
        ( hd<h_debut AND h_f> h_debut + durees ));
    BEGIN
    OPEN cur_spec;
    FETCH cur_spec INTO
        v_id,
        v_hd,
        h_f;
    IF cur_spec%notfound THEN --pas de croisement entre les spectacles
        RETURN true;
    ELSE
        dbms_output.put_line('le lieu dont l''ID est : '|| l || ' est occupé le '|| da
                             || ' à '|| hd|| ' heure');
        RETURN false;
    END IF;
END spec_valid; 
/****************ajouter spectacle***************/
CREATE OR REPLACE PROCEDURE ajout_spec (
    tit         spectacle.titre%TYPE,
    date_spec   spectacle.dateS%TYPE,
    h_d          spectacle.h_debut%TYPE,
    D          spectacle.dureeS%TYPE,
    nb_S         spectacle.nbrspectateur%TYPE,
    id_l         spectacle.idlieu%TYPE
) IS
BEGIN                
     IF spec_valid(date_spec, h_d, D, id_l) THEN  -- LE LIEU EST BIEN DISPONIBLE PENDANT LA DATE ET LA PERIODE DEMANDÉES                 
            INSERT INTO spectacle VALUES (seq2.NEXTVAL,tit,date_spec,h_d, D,nb_S,id_l);
        ELSE
            raise_application_error(-20032, 'Lieu n''est pas disponible pendant l''horaire demandé!');
        END IF;
END;
/
/*********test*******/
set serveroutput on
execute ajout_spec('24 odeurs','31/01/2021',19,3,1500,16);
select * from spectacle where titre='24 odeurs';
/********************annuler spectacle****************************************/
       /*******teste sii id spectacle existe ou nn*****************/
CREATE OR REPLACE FUNCTION idspec_exist (id_spec spectacle.idspec%TYPE) RETURN BOOLEAN IS
    ids spectacle.idspec%TYPE;
BEGIN
    SELECT idspec INTO ids
    FROM spectacle
    WHERE idspec = id_spec;    
    RETURN TRUE ;
EXCEPTION
    WHEN no_data_found THEN
        RETURN false;
END idspec_exist;
      /***************procedure annuler*********/
CREATE OR REPLACE PROCEDURE annul_spec (
    id_spec spectacle.idspec%TYPE
) IS
BEGIN
    IF idspec_exist(id_spec) THEN
        UPDATE spectacle SET h_debut = 0
        WHERE idspec = id_spec;
        dbms_output.put_line('annlation avec succee');

    ELSE
        raise_application_error(-20002, 'IDSPEC donné n''est pas valide!=');
    END IF;
    commit;
END;
/
    /*********test**********/
set serveroutput on
execute annul_spec(8);
/********************************modifier spectacles*************************************/
	/*****modifier titre de spectacle */
CREATE OR REPLACE PROCEDURE modif_titre(id spectacle.IDSPEC%TYPE,titre1 spectacle.TITRE%TYPE)
IS
t boolean;
BEGIN 
 t := idspec_exist(id) ;
 if t then 
     update spectacle 
     set titre=titre1
     where idspec = id; 
else
    RAISE_APPLICATION_ERROR(-20115,'ce IDSPEC est INEXSISTANT!');
END IF;         
END modif_titre;
/
      /****test**********/
SET SERVEROUTPUT ON;
DECLARE 
    BEGIN
    modif_titre(9,'Melouf');
    END;
select * from spectacle where idspec=9;
/**********************modif_date_spectacle***********************/       
Create or replace PROCEDURE modif_date(id in NUMBER,nvdate in VARCHAR2) IS
t boolean;
    BEGIN 
        t := idspec_exist(id) ;
        if t then 
            update spectacle set DATES=to_date(nvdate,'DD-MM-YYYY') where idspec=id;
            dbms_output.put_line('date modifié avec succee');
        else
            RAISE_APPLICATION_ERROR(-20115,'ce IDSPEC est INEXSISTANT!');
        END IF;
END modif_date;
/
 /******test*****/
 DECLARE 
    BEGIN
    modif_date(9,'31/03/2021');
    END; 
    select * from spectacle where idspec=9;
    

 /**** trigger modifiant heure de debut de chaque rubrique , un decalage se repercute ds chacun *****/
CREATE OR REPLACE  TRIGGER trigger_after_modif_hdebut_s
AFTER UPDATE   
OF H_DEBUT  
ON spectacle  
FOR EACH ROW    
DECLARE 
   difference  spectacle.DUREES%TYPE;
   idrubrique rubrique.IDRUB%TYPE;
   nb_rubriques int ;
   heure_d spectacle.DUREES%TYPE;
   CURSOR cur  IS 
        SELECT IDRUB,H_DEBUTR  
        FROM rubrique
        WHERE idspec = :NEW.idspec;
BEGIN  
	difference := :NEW.H_DEBUT - :OLD.H_DEBUT;
   dbms_output.put_line(difference);
    OPEN cur; 
       LOOP
           FETCH cur INTO idrubrique,heure_d;
           EXIT	WHEN	NOT	cur%FOUND;		
              dbms_output.put_line(idrubrique);        
           update rubrique set H_DEBUTR = H_DEBUTR + difference  where idspec=:NEW.idspec and IDRUB = idrubrique;
        END	LOOP;
END;
					/********************* modifier heure_debut_spec************************/
Create or replace PROCEDURE modif_heure_debut(id in NUMBER,heure in NUMBER)
IS
t boolean;
BEGIN 
 t := idspec_exist(id) ;
 if t then 
        update spectacle set H_DEBUT=heure where idspec=id;
        DBMS_OUTPUT.PUT_LINE ('update heure de debut avec success');
else
    RAISE_APPLICATION_ERROR(-20119,'ce IDSPEC est INEXSISTANT!');
END IF;
COMMIT;
END modif_heure_debut;
/
/******test****/
SET SERVEROUTPUT ON 
DECLARE
BEGIN 
modif_heure_debut(11,21);
END;
select * from spectacle where idspec=11;
select * from rubrique where idspec=11;
/**** trigger modifiant les dures des rubriques apres modif de duree de spectacle**/
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
/*********************modifier duree_spec ************************/
CREATE OR REPLACE PROCEDURE modif_duree(id in NUMBER,duree1 in NUMBER) 
IS
t boolean;
BEGIN 
 t := idspec_exist(id) ;
 if t then 
   update spectacle set DUREES=duree1 where idspec=id;
   DBMS_OUTPUT.PUT_LINE ('update avec success'); 
else
    RAISE_APPLICATION_ERROR(-20115,'ce IDSPEC est INEXSISTANT!');
END IF;   
commit;
END modif_duree;
SET SERVEROUTPUT ON 
DECLARE
BEGIN 
modif_duree(13,3);
END;
select * from spectacle where idspec=13;
select * from rubrique where idspec=13;
/**trigger pr verfier que nbr specateur est suffisant pr le lieu corresspondant **/
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
  	/**********************modif_nbr_spectateur***********************/
Create or replace PROCEDURE modif_spectateur(id in NUMBER,nbr IN NUMBER )
IS
t boolean;
BEGIN 
    t := idspec_exist(id) ;
    if t then 
        update spectacle set nbrSpectateur=nbr where idspec=id;
        DBMS_OUTPUT.PUT_LINE ('update du nombre de spectateurs avec success'); 
    else
        RAISE_APPLICATION_ERROR(-20115,'ce IDSPEC est INEXSISTANT!');
    END IF; 
END modif_spectateur;
SET SERVEROUTPUT ON;
DECLARE 
    BEGIN
    modif_spectateur(14,1200);
    END; 
    select * from spectacle where idspec=14;
/****fonction pour verifier que le spectacle est validé*******/  
CREATE OR REPLACE FUNCTION  spec_valid (nvdate spectacle.dates%TYPE, nv_h_debut spectacle.h_debut%TYPE,
nv_duree spectacle.durees%TYPE, nv_lieu spectacle.idlieu%TYPE)
 RETURN BOOLEAN AS
    v_id   spectacle.idspec%TYPE;
    v_nv_h_debut   spectacle.h_debut%TYPE;
    v_hd  spectacle.h_debut%TYPE;
    nv_heure_fin spectacle.h_debut%TYPE := nv_h_debut + nv_duree ; -- hf = heure fin du spectacles  deja existants
    dur  spectacle.durees%TYPE;

    CURSOR cur_spec  IS 
        SELECT idspec, h_debut,durees    
        FROM spectacle
        WHERE
            dateS = nvdate
            AND idlieu = nv_lieu    
    		AND ( nv_h_debut  BETWEEN  h_debut AND   h_debut + durees  AND  nv_h_debut  NOT IN (h_debut+durees) 
            OR  nv_heure_fin  BETWEEN  h_debut AND   h_debut + durees  AND  nv_heure_fin  NOT IN (h_debut )       
            OR ( nv_h_debut <h_debut AND nv_heure_fin > h_debut + durees )
    );
    BEGIN
        OPEN cur_spec;
        FETCH cur_spec INTO
            v_id,
            v_hd,
            dur;
        IF cur_spec%notfound THEN --pas de croisement entre les spectacles
            RETURN true;
        ELSE
            RETURN false;
            RAISE_APPLICATION_ERROR(-20119,'Impossible d avoir un croisement entre 2 spectacles');
        END IF;
END spec_valid; 
	/**********************modif_lieu_spectacle***********************/
Create or replace PROCEDURE modif_lieu(id in NUMBER,id_nvlieu spectacle.IDLIEU%TYPE )
IS
t boolean;
BEGIN 
    t := idspec_exist(id) ;
    if t then 
        update spectacle set IDLIEU=id_nvlieu where idspec=id;
        DBMS_OUTPUT.PUT_LINE ('modification du lieu avec success'); 
    else
        RAISE_APPLICATION_ERROR(-20117,'ce IDSPEC est INEXSISTANT!');
    END IF; 
END modif_lieu;
/
SET SERVEROUTPUT ON;
DECLARE 
    BEGIN
    modif_lieu(9,3);
    END;  
select * from spectacle where idspec=9;
/***************rechercher rubrique à partir idspectacle *************/
CREATE OR REPLACE FUNCTION rechercher_rub_idspec (ids rubrique.idspec%TYPE) 
RETURN BOOLEAN IS
    vid  rubrique.idspec%TYPE;
BEGIN
            SELECT COUNT(idspec) 
            into vid /**select pr voir si idrub existe deja dans yable ou non */
            FROM rubrique
            WHERE
                idspec = ids;
            if vid = 0 then
                 RETURN false;
            else 
            RETURN true;
            END IF;
END rechercher_rub_idspec;
/***************test*************/
SET SERVEROUTPUT ON;
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
  /******************recherche  rubrique avec idratiste donnée**************/     
 CREATE OR REPLACE FUNCTION rechercher_rub_par_idart (ida rubrique.idart%TYPE) 
RETURN BOOLEAN IS
    vid  rubrique.idart%TYPE;
BEGIN
            SELECT COUNT(idart)
            into vid
            FROM rubrique
            WHERE
                idart = ida;
            if vid = 0 then
                RETURN false;
            else 
            
            RETURN true;
            END IF;
END rechercher_rub_par_idart;
/***************test*************/
SET SERVEROUTPUT ON;
DECLARE 
    t BOOLEAN;
    BEGIN
    t :=rechercher_rub_par_idart(4);
  IF t THEN
     dbms_output.put_line('oui il existe une rubrique pourr cet artiste');   
    ELSE
    dbms_output.put_line('non pas de rubrique pourr cet artiste !!'); 
    END IF; 
    END;
  /******************recherche  rubrique avec nom de l'atiste donnée**************/     
create or replace function rechercher_rub_par_nomartiste ( nom artiste.nomart%TYPE) 
RETURN BOOLEAN IS
    t BOOLEAN;
        vida artiste.idart%TYPE;
    BEGIN
       select IDART into vida
       from artiste 
     where upper(NOMART) like upper(nom) ;
     t := rechercher_rub_par_idart (vida);  --on a utiliser une fonction intermediaires
      if t then 
            return true;
      else 
            return false;
      end if;
 END rechercher_rub_par_nomartiste;
/***************test*************/
SET SERVEROUTPUT ON
DECLARE 
    t BOOLEAN;
BEGIN
    t := rechercher_rub_par_nomartiste('najla'); 
    if (t) then 
       dbms_output.put_line('oui il existe une rubrique correspondant à cet artiste'); 
     else
        dbms_output.put_line('non il n existe pas une rubrique correspondant à cet artiste '); 
      end if;
END;
/***************rechercher spectacle à partir idspectacle *************/
CREATE OR REPLACE FUNCTION recherche_spec_par_idspec (id_spec spectacle.idspec%TYPE) RETURN BOOLEAN IS
    ids spectacle.idspec%TYPE;
BEGIN
    SELECT idspec INTO ids
    FROM spectacle
    WHERE idspec = id_spec;
    IF ids = id_spec THEN
        RETURN true;
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        RETURN false;
END recherche_spec_par_idspec;
/***************rechercher rubrique à partir du titre *************/
CREATE OR REPLACE FUNCTION recherche_spec_titre (nvtitre spectacle.titre%TYPE) RETURN BOOLEAN IS
    v_titre spectacle.titre%TYPE;
BEGIN
    SELECT titre INTO v_titre
    FROM spectacle
    WHERE upper(titre) = upper(nvtitre);
    RETURN true;
EXCEPTION
    WHEN no_data_found THEN
        RETURN false;
END recherche_spec_titre;
/***test****/
DECLARE
    t1 Boolean;
    t2 BOOLEAN;
BEGIN
    t1 := recherche_spec_par_idspec(31);
    t2:=recherche_spec_titre('24 odeurs');
    IF t1 and t2 THEN
        dbms_output.put_line('ce spectacle existe');
    ELSE
        dbms_output.put_line('n''existe pas');
    END IF;
END;
/*******verifier si artiste dispo ou non*************/
create or replace FUNCTION artiste_dispo (
    id_art   artiste.idart%TYPE,
    d        spectacle.dates%TYPE,
    hd       rubrique.h_debutr%TYPE,
    duree    rubrique.dureerub%TYPE,
    typer        rubrique.type%TYPE
) RETURN BOOLEAN IS
    hf  rubrique.h_debutr%TYPE := hd + duree; --heure fin  de la rubrique a ajouter 
    vida  rubrique.idart%TYPE;  
    vs    artiste.specialite%TYPE;
    typea artiste.specialite%TYPE;
    CURSOR cur_rubart IS
    SELECT r.idart         
    FROM rubrique r,spectacle s
    WHERE r.idspec = s.idspec
    AND s.dates = d    -- la date donnée pour l'artiste donné
    AND idart = id_art
    AND ( hd BETWEEN  h_debutr AND   h_debutr + dureerub  AND  hd NOT IN (h_debutr+dureerub) 
            OR            
          hf BETWEEN  h_debutr AND   h_debutr + dureerub  AND  hf NOT IN (h_debutr )       
              OR 
        ( hd<h_debutr AND hf> h_debutr + dureerub )
    );
BEGIN
    SELECT  DISTINCT(a.specialite )    -- determiner la specialite de l'artiste
     INTO vs
    FROM artiste a ,rubrique r
    WHERE a.idArt=r.idArt
    AND a.idart = id_art;
typea:=typer ;
IF typer='comédie' THEN 
        typea:= 'humoriste' ;
END IF ;
IF typer='theatre' THEN 
        typea:= 'acteur' ;
END IF ;
IF typer='dance' THEN 
    typea:= 'danseur ' ;
END IF ;
IF typer='imitation' THEN 
       typea:= 'imitateur' ;
END IF ;
IF typer='magie' THEN 
       typea:= 'magicien' ;
END IF ;
IF typer='musique' THEN 
        typea:= 'musicien' ;
END IF ;
IF typer='chant' THEN 
       typea:= 'chanteur' ;
END IF ;
IF vs = typea THEN    -- verifier si l'artiste est demandé pour une rubrique adequate avec sa specialité
OPEN cur_rubart;
FETCH cur_rubart INTO vida;                
IF cur_rubart%notfound THEN  -- pas de croisement entre le les horaires souhaitées et les horaires deja fixé dans la base 
    dbms_output.put_line('artiste disponible');
     RETURN true;
ELSE
     dbms_output.put_line('artiste non disponible');
    RETURN false;
END IF;
ELSE
     dbms_output.put_line('Probleme de specialitée ou id inex!!');
    RETURN false;
END IF;
END artiste_dispo;
/*******************************rub_valid******************************/
create or replace FUNCTION rub_valid (
    ids     rubrique.idspec%TYPE,
    hd      rubrique.h_debutr%TYPE,
    duree   rubrique.dureerub%TYPE
) RETURN BOOLEAN AS
    hf   rubrique.h_debutr%TYPE := hd + duree; --heure fin  de la rubrique a ajouter 
-- variables pour les SELECT INTO
    vds  spectacle.durees%TYPE;  -- duree spectacle
    vsdr  rubrique.dureerub%TYPE; -- somme des durees rubriques
    vhds  spectacle.h_debut%TYPE; -- heure debut spectacle
    vcount INT;                    -- nombre de rubrique pour un spectacle
-- variables pour les 3 verification : 
    test_duree        BOOLEAN;
    test_commence     BOOLEAN;
    test_croisement   BOOLEAN;
-- variables pour le cursor select into 
    chd   spectacle.h_debut%TYPE;
    chf  spectacle.h_debut%TYPE;
    CURSOR cur_rub IS -- date debut et date fin de chaque rubrique qui se croise avec la rubrique à ajouter 
    SELECT h_debutr,h_debutr + dureerub h_finr
     FROM rubrique
     WHERE idspec = ids
     AND((hd BETWEEN h_debutr AND h_debutr +dureerub AND  hd NOT IN (h_debutr+dureerub) 
                OR
        (hf BETWEEN h_debutr AND h_debutr +dureerub AND  hf NOT IN (h_debutr ) )
                OR 
        ( hd<h_debutr AND hf> h_debutr + dureerub ) ));
    BEGIN
        SELECT durees,h_debut INTO vds,vhds
        FROM spectacle
        WHERE idspec = ids;  
        IF hd + duree <= vhds + vds AND hd >= vhds THEN -- l'heure de debut et de la fin de la rubrique sont incluses dans l'horaire du spectacle                
            OPEN cur_rub;
            FETCH cur_rub INTO chd,chf;
            IF cur_rub%notfound THEN --il n ya aucune rubrique qui se croise  avec la rubrique qu'on veut ajouter 
                    SELECT  COUNT(*) INTO vcount                            -- le nombre de rubrique du spectacle donné                     
                    FROM rubrique
                    WHERE idspec = ids;
                    IF vcount < 3 THEN   
                        SELECT SUM(dureerub) INTO vsdr
                        FROM  rubrique r
                        WHERE idspec = ids;
                        IF vds - vsdr - duree < 0 THEN --duree spectacle - somme de duree des rubrique existants - duree de la rubrique aa ajouter 
                            dbms_output.put_line('prob durree');
                            RETURN FALSE;
                        ELSE
                            RETURN TRUE;
                        END IF; 
                    ELSE
                        dbms_output.put_line('exist 3');
                        RETURN FALSE;
                    END IF;
                ELSE
                    dbms_output.put_line('rubriques croisent');
                    RETURN FALSE ; 
                END IF;
        ELSE
            dbms_output.put_line('prob rubrique spect');
            RETURN FALSE;
        END IF ;
END rub_valid; 

/*** test******/
DECLARE
    t BOOLEAN;
BEGIN
        t := rub_valid(19,23,1);
    IF t THEN
        dbms_output.put_line('rubrique valide');
    ELSE
        dbms_output.put_line('no');
    END IF;
END;







/********************ajout_rub*********************/

CREATE OR REPLACE PROCEDURE ajout_rub (
    ids   spectacle.idspec%TYPE,
    idart   artiste.idart%TYPE,
    hd_reb   rubrique.h_debutr%TYPE,
    Duree   rubrique.dureerub%TYPE,
    typer   rubrique.type%TYPE
) IS    
datespectacle spectacle.dates%TYPE;
BEGIN
        SELECT dates INTO datespectacle
        from spectacle
        WHERE idspec = ids;
 IF artiste_dispo(idart, datespectacle, hd_reb, Duree,typer ) THEN             -- L'ARTISTE DISPONIBLE DE HDR JUSQU'A HDR+DUR
           IF rub_valid(ids, hd_reb, Duree) THEN           -- LA PERIODE DEMANDÉ POUR LA RUBRIQUE EST DISPONIBLE  
                 INSERT INTO rubrique VALUES ( seq2.NEXTVAL,ids,idart,hd_reb,Duree,typer);
                ELSE
                    raise_application_error(-20038, 'Horaire invalide!');
                END IF;
            ELSE
                raise_application_error(-20039, 'verifier la disponibilité ou le type de l''artiste!');
            END IF;
END;
/
/****************TEST**************/

BEGIN
        ajout_rub(9,6,11,1,'Musique');
END;
/**  triggers avant modification de duree rubrique**/
CREATE OR REPLACE TRIGGER trigger_modif_duree_rub
BEFORE update of dureerub
ON RUBRIQUE
FOR EACH ROW         
DECLARE
    V_DUREES spectacle.DUREES%TYPE ;    
BEGIN
    SELECT DUREES INTO V_DUREES  FROM spectacle WHERE IDSPEC = :NEW.IDSPEC;    
    IF  :NEW.DUREERUB <= V_DUREES then 
            dbms_output.put_line('durée de rubrique  par rapport a celle du spectacle verifiée !');
     ELSE 
            RAISE_APPLICATION_ERROR(-20500,'la dureé de rubrique ne peut pas dépasser celle du spectacle');
    END IF;
    END;
/**  triggers avant modification de heure de debut rubrique**/        
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
        /*********************************Modification rubrique*******************************************/
/*********************package modif_rubrique************************/
CREATE OR REPLACE PACKAGE modif_rubrique
AUTHID CURRENT_USER 
AS 
 FUNCTION idrub_exist ( id_rub rubrique.idrub%TYPE) RETURN BOOLEAN;
PROCEDURE modif_artiste(id in NUMBER,idartiste in number);
PROCEDURE modif_heure_debut(id in NUMBER,heure in number);
FUNCTION validation_artiste (v_idartiste rubrique.idart%TYPE) RETURN BOOLEAN ;
PROCEDURE modif_duree(id in NUMBER,duree1 in NUMBER);
END modif_rubrique; 
/

 cREATE OR REPLACE PACKAGE BODY modif_rubrique AS 
 /*****id rubrique existe ou pas********************/
 FUNCTION idrub_exist ( id_rub rubrique.idrub%TYPE
) RETURN BOOLEAN IS
    idr rubrique.idrub%TYPE;
BEGIN
    SELECT idrub INTO idr
    FROM rubrique
    WHERE
        idrub = id_rub;
    IF idr = id_rub THEN
        RETURN true;
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        RETURN false;
END idrub_exist; 
/*********************fonction validation************************/
FUNCTION validation_artiste (
v_idartiste rubrique.idart%TYPE
) RETURN BOOLEAN AS
v_id artiste.idart%TYPE;
CURSOR cur_art IS SELECT idart
FROM artiste;
BEGIN
OPEN cur_art;
loop
   FETCH cur_art INTO V_id;
   exit when (cur_art%notfound);
         if(v_id=v_idartiste) then
               RETURN true;
         end if;	 

end loop;
close cur_art;
dbms_output.put_line('l''artiste dont I"ID est :'||v_idartiste||'n''existe pas');
return false;
end validation_artiste;
/*********************modif art************************/
PROCEDURE modif_artiste(id in NUMBER,idartiste in NUMBER)
is
begin
   if validation_artiste(idartiste) and idrub_exist(id) then
      update rubrique set idart=idartiste where idrub=id;
      dbms_output.put_line('modif success');
   else 
      raise_application_error(-20031,'cet artiste n''existe pas');
   end if;
end modif_artiste; 
/*********************modif_heure_debut************************/
PROCEDURE modif_heure_debut(id in NUMBER,heure in number)
IS
BEGIN  
     if  idrub_exist(id) then
           update rubrique set h_debutR=heure where idrub=id; 
           dbms_output.put_line('modif success');
    else 
      raise_application_error(-20031,' id n''existe pas'||id);
  END IF;        
END modif_heure_debut;
/*********************modif_duree************************/
PROCEDURE modif_duree(id in NUMBER,duree1 in number)
IS
BEGIN  
 if  idrub_exist(id) then
     update rubrique set dureerub=duree1 where idrub=id; 
     dbms_output.put_line('modif success');
Else 
      raise_application_error(-20032,' id n''existe pas'||id);
  END IF;
          
END modif_duree;
end modif_rubrique;
/************test***********************/
set serveroutput on
execute modif_rubrique.modif_duree(15,2);
execute modif_rubrique.modif_artiste(15,4);
execute modif_rubrique.modif_heure_debut(15,19);
/*********supprimer rubrique*******/
create or replace PROCEDURE supprimer_rub (idr rubrique.idrub%TYPE) IS
    vids   rubrique.idspec%TYPE;
    vds    spectacle.dates%TYPE;
BEGIN
            DELETE FROM rubrique
            WHERE
                idrub = idr;

            dbms_output.put_line('1 Row was dropped successfuly');
        exception 
        When no_data_found then
            dbms_output.put_line('pas de suppression ! verifiez id rub');
END supprimer_rub;
/
/****test****/
set serveroutput on
execute supprimer_rub(15);













