CREATE DATABASE `CARLOCA`;

CREATE TABLE CARLOCA.CLIENTE (
	ID INT auto_increment NOT NULL,
	NOME varchar(100) NOT NULL,
	DATA_NACIMENTO DATE NOT NULL,
	CPF varchar(11) NOT NULL,
	REGISTRO_MOTORISTA varchar(11) NOT NULL,
	CONSTRAINT CLIENTE_PK PRIMARY KEY (ID)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE CARLOCA.CLIENTE ADD ESTA_ALUGANDO BIT DEFAULT 0 NOT NULL;

CREATE TABLE CARLOCA.ENDERECO (
	ID INT auto_increment NOT NULL,
	RUA varchar(100) NOT NULL,
	NUMERO varchar(10) NOT NULL,
	COMPLEMENTO varchar(10) NULL,
	BAIRO varchar(100) NOT NULL,
	CIDADE varchar(100) NOT NULL,
	ESTADO varchar(2) NOT NULL,
	CEP varchar(8) NOT NULL,
	CONSTRAINT ENDERECO_PK PRIMARY KEY (ID)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE CARLOCA.CARRO (
	ID INT auto_increment NOT NULL,
	MODELO varchar(25) NOT NULL,
	MONTADORA varchar(25) NOT NULL,
	COR ENUM('BRANCO','PRETO','PRATA') NOT NULL,
	VERSAO varchar(100) NOT NULL,
	ESTA_ALUGADO BIT DEFAULT 0 NOT NULL,
	QUILOMETRAGEM FLOAT(10,2) DEFAULT 0 NOT NULL,
	CONSTRAINT CARRO_PK PRIMARY KEY (ID)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE CARLOCA.ALUGUEL_ENTREGA (
	ID INT auto_increment NOT NULL,
	CLIENTE_ID INT NOT NULL,
	CARRO_ID INT NOT NULL,
	ENDEREÇO_ID INT NOT NULL,
	CATEGORIA ENUM('HATCH','SEDAM COMPACTO','SEDAM MEDIO','SUV','PICAPE') NOT NULL,
	MODALIDADE ENUM('DIARIA') NOT NULL,
	CONSTRAINT ALUGUEL_ENTREGA_PK PRIMARY KEY (ID),
	CONSTRAINT ALUGUEL_ENTREGA_FK FOREIGN KEY (CLIENTE_ID) REFERENCES CARLOCA.CLIENTE(ID),
	CONSTRAINT ALUGUEL_ENTREGA_FK_1 FOREIGN KEY (CARRO_ID) REFERENCES CARLOCA.CARRO(ID),
	CONSTRAINT ALUGUEL_ENTREGA_FK_2 FOREIGN KEY (ENDEREÇO_ID) REFERENCES CARLOCA.ENDERECO(ID)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE CARLOCA.ALUGUEL_DEVOLUCAO (
	ID INT auto_increment NOT NULL,
	ALUGUEL_ENTREGA_ID INT NOT NULL,
	ENDERECO_DEVOLUCAO_ID INT NOT NULL,
	QUILOMETRAGEM_RODADA FLOAT(10,2) NOT NULL,
	CONSTRAINT ALUGUEL_DEVOLUCAO_PK PRIMARY KEY (ID),
	CONSTRAINT ALUGUEL_DEVOLUCAO_FK FOREIGN KEY (ALUGUEL_ENTREGA_ID) REFERENCES CARLOCA.ALUGUEL_ENTREGA(ID),
	CONSTRAINT ALUGUEL_DEVOLUCAO_FK_1 FOREIGN KEY (ENDERECO_DEVOLUCAO_ID) REFERENCES CARLOCA.ENDERECO(ID)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE CARLOCA.ALUGUEL_DEVOLUCAO ADD CONSTRAINT ALUGUEL_DEVOLUCAO_UN UNIQUE KEY (ALUGUEL_ENTREGA_ID);

CREATE TRIGGER MUDAR_STATUS_CARRO_ALUGADO
AFTER INSERT OR UPDATE
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	UPDATE CARLOCA.CARRO SET ESTA_ALUGADO = 1 WHERE ID = NEW.CARRO_ID;
END

CREATE TRIGGER MUDAR_STATUS_CARRO_ALUGADO_UPDATE
AFTER UPDATE 
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN
	IF(NEW.CARRO_ID != OLD.CARRO_ID) THEN
		UPDATE CARLOCA.CARRO SET ESTA_ALUGADO = 1 WHERE ID = NEW.CARRO_ID;
		UPDATE CARLOCA.CARRO SET ESTA_ALUGADO = 0 WHERE ID = OLD.CARRO_ID;
	END IF;
END 	

CREATE TRIGGER MUDAR_STATUS_CARRO_ALUGADO_DELETE
AFTER DELETE
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	UPDATE CARLOCA.CARRO SET ESTA_ALUGADO = 0 WHERE ID = OLD.CARRO_ID;
END

CREATE TRIGGER BLOQUEAR_CARRO_JA_ALUGADO
BEFORE INSERT
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	SET @STATUS := (SELECT ESTA_ALUGADO FROM CARLOCA.CARRO WHERE ID=NEW.CARRO_ID);
	IF(@STATUS = 1)THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ESSE CARRO NAO PODE SER ALUGADO PORQUE JA ESTA ALUGADDO POR OUTRO CLIENTE';
	END IF;
END

CREATE TRIGGER BLOQUEAR_CARRO_JA_ALUGADO_UPDATE
BEFORE UPDATE
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	SET @STATUS := (SELECT ESTA_ALUGADO FROM CARLOCA.CARRO WHERE ID=NEW.CARRO_ID);
	IF(@STATUS = 1)THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ESSE CARRO NAO PODE SER ALUGADO PORQUE JA ESTA ALUGADDO POR OUTRO CLIENTE';
	END IF;
END

CREATE TRIGGER MUDAR_STATUS_CLIENTE_ALUGANDO
AFTER INSERT
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	UPDATE CARLOCA.CLIENTE  SET ESTA_ALUGANDO = 1 WHERE ID = NEW.CLIENTE_ID;
END;

CREATE TRIGGER MUDAR_STATUS_CLIENTE_ALUGANDO_UPDATE
AFTER UPDATE 
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	IF(NEW.CLIENTE_ID != OLD.CLIENTE_ID) THEN
		UPDATE CARLOCA.CLIENTE SET ESTA_ALUGANDO = 1 WHERE ID = NEW.CLIENTE_ID;
		UPDATE CARLOCA.CLIENTE SET ESTA_ALUGANDO = 0 WHERE ID = OLD.CLIENTE_ID;
	END IF;
END

CREATE TRIGGER BLOQUEAR_CLIENTE_JA_ALUGANDO
BEFORE INSERT
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	SET @STATUS := (SELECT ESTA_ALUGANDO FROM CARLOCA.CLIENTE WHERE ID=NEW.CLIENTE_ID);
	IF(@STATUS = 1)THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ESSE CLIENTE NAO PODE ALUGAR O CARRO PORQUE JA ESTA ALUGANDO OUTRO';
	END IF;
END

CREATE TRIGGER BLOQUEAR_CLIENTE_JA_ALUGANDO_UPDATE
BEFORE UPDATE
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	SET @STATUS := (SELECT ESTA_ALUGANDO FROM CARLOCA.CLIENTE WHERE ID=NEW.CLIENTE_ID);
	IF(@STATUS = 1)THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ESSE CLIENTE NAO PODE ALUGAR O CARRO PORQUE JA ESTA ALUGANDO OUTRO';
	END IF;
END


CREATE TRIGGER MUDAR_STATUS_CLIENTE_ALUGANDO_DELETE
AFTER DELETE
ON ALUGUEL_ENTREGA FOR EACH ROW
BEGIN 
	UPDATE CARLOCA.CLIENTE SET ESTA_ALUGANDO = 0 WHERE ID = OLD.CLIENTE_ID;
END


CREATE TRIGGER AUMENTAR_QUILOMETRAGEM_CARRO
AFTER INSERT
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	SET @QUILOMETROS := (SELECT QUILOMETRAGEM FROM CARLOCA.CARRO c JOIN CARLOCA.ALUGUEL_ENTREGA a 
		ON c.ID = a.CARRO_ID 
		WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID );
	SET @CARRO := (SELECT CARRO_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID);
	UPDATE CARLOCA.CARRO SET QUILOMETRAGEM = (NEW.QUILOMETRAGEM_RODADA + @QUILOMETROS) WHERE ID = @CARRO;
END

CREATE TRIGGER AUMENTAR_QUILOMETRAGEM_CARRO_UPDATE
AFTER UPDATE 
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	SET @QUILOMETROS := (SELECT QUILOMETRAGEM FROM CARLOCA.CARRO c JOIN CARLOCA.ALUGUEL_ENTREGA a 
		ON c.ID = a.CARRO_ID 
		WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID );
	SET @CARRO := (SELECT CARRO_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID);
	IF(NEW.QUILOMETRAGEM_RODADA > OLD.QUILOMETRAGEM_RODADA) THEN
		UPDATE CARLOCA.CARRO SET QUILOMETRAGEM = ((NEW.QUILOMETRAGEM_RODADA - OLD.QUILOMETRAGEM_RODADA) + @QUILOMETROS) WHERE ID = @CARRO;
	ELSEIF(NEW.QUILOMETRAGEM_RODADA < OLD.QUILOMETRAGEM_RODADA) THEN
		UPDATE CARLOCA.CARRO SET QUILOMETRAGEM = ((@QUILOMETROS - OLD.QUILOMETRAGEM_RODADA) + NEW.QUILOMETRAGEM_RODADA) WHERE ID = @CARRO;
	END IF;
END	


CREATE TRIGGER MUDAR_STATUS_CARRO
AFTER INSERT
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	SET @CARRO := (SELECT CARRO_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID);
	UPDATE CARLOCA.CARRO SET ESTA_ALUGADO = 0 WHERE ID = @CARRO;
END


CREATE TRIGGER MUDAR_STATUS_CARRO_UPDATE
AFTER UPDATE
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	IF(NEW.ALUGUEL_ENTREGA_ID != OLD.ALUGUEL_ENTREGA_ID) THEN 
		SET @CARRO_NOVO := (SELECT CARRO_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID);
		SET @CARRO_VELHO := (SELECT CARRO_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = OLD.ALUGUEL_ENTREGA_ID);
		UPDATE CARLOCA.CARRO SET ESTA_ALUGADO = 0 WHERE ID = @CARRO_NOVO;
		UPDATE CARLOCA.CARRO SET ESTA_ALUGADO = 1 WHERE ID = @CARRO_VELHO;
	END IF;
END

CREATE TRIGGER ALTERAR_QUILOMETRAGEM_CARRO
AFTER UPDATE 
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	IF(NEW.ALUGUEL_ENTREGA_ID != OLD.ALUGUEL_ENTREGA_ID) THEN 
		SET @CARRO_NOVO := (SELECT CARRO_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID);
		SET @CARRO_VELHO := (SELECT CARRO_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = OLD.ALUGUEL_ENTREGA_ID);
		SET @QUILOMETROS_CARRO_NOVO := (SELECT QUILOMETRAGEM FROM CARLOCA.CARRO c JOIN CARLOCA.ALUGUEL_ENTREGA a 
		ON c.ID = a.CARRO_ID 
		WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID );
		SET @QUILOMETROS_CARRO_VELHO := (SELECT QUILOMETRAGEM FROM CARLOCA.CARRO c JOIN CARLOCA.ALUGUEL_ENTREGA a 
		ON c.ID = a.CARRO_ID 
		WHERE a.ID = OLD.ALUGUEL_ENTREGA_ID );
	
		UPDATE CARLOCA.CARRO SET QUILOMETRAGEM = @QUILOMETROS_CARRO_NOVO + NEW.QUILOMETRAGEM_RODADA WHERE ID = @CARRO_NOVO;
		UPDATE CARLOCA.CARRO SET QUILOMETRAGEM = @QUILOMETROS_CARRO_VELHO - OLD.QUILOMETRAGEM_RODADA WHERE ID = @CARRO_VELHO;
	END IF;
END


CREATE TRIGGER VERIFICAR_QUILOMETRAGEM_NEGATIVA
BEFORE INSERT
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	IF(NEW.QUILOMETRAGEM_RODADA <= 0) THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A QUILOMETRAGEM RODDADA TEM QUE SEM UM VALOR MAIOR QUE 0';
	END IF;
END


CREATE TRIGGER VERIFICAR_QUILOMETRAGEM_NEGATIVA_UPDATE
BEFORE UPDATE
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	IF(NEW.QUILOMETRAGEM_RODADA <= 0) THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A QUILOMETRAGEM RODDADA TEM QUE SEM UM VALOR MAIOR QUE 0';
	END IF;
END

CREATE TRIGGER MUDAR_STATUS_CLIENTE
AFTER INSERT
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	SET @CLIENTE := (SELECT CLIENTE_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID);
	UPDATE CARLOCA.CLIENTE SET ESTA_ALUGANDO = 0 WHERE ID = @CLIENTE;
END

CREATE TRIGGER MUDAR_STATUS_CLIENTE_UPDATE
AFTER UPDATE
ON ALUGUEL_DEVOLUCAO FOR EACH ROW
BEGIN 
	IF(NEW.ALUGUEL_ENTREGA_ID != OLD.ALUGUEL_ENTREGA_ID) THEN 
		SET @CLIENTE_NOVO := (SELECT CLIENTE_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = NEW.ALUGUEL_ENTREGA_ID);
		SET @CLIENTE_VELHO := (SELECT CLIENTE_ID FROM CARLOCA.ALUGUEL_ENTREGA a WHERE a.ID = OLD.ALUGUEL_ENTREGA_ID);
		UPDATE CARLOCA.CLIENTE SET ESTA_ALUGANDO = 0 WHERE ID = @CLIENTE_NOVO;
		UPDATE CARLOCA.CLIENTE SET ESTA_ALUGANDO = 1 WHERE ID = @CLIENTE_VELHO;
	END IF;
END

