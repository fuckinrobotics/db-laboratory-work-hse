 /*
Процедура, проверяющая некоторые ограничения целостности.
*/
CREATE  OR REPLACE FUNCTION  doCheking()  RETURNS  TRIGGER  AS $$ 
BEGIN
	IF (new.deliveryDate > now()) 
		THEN RAISE 'Дата поставки не может быть больше текущей.';
	END IF;
	
	IF (NOT (remainderOfGoods BETWEEN 0 AND quantityOfReceivedproduct)) 
	  THEN RAISE 'Остаток должен быть не больше количества поступившего товара, не меньше 0.';
	END IF;
	
	IF (NOT (quantityOfReceivedProduct > 0)) 
	  THEN RAISE 'Количество дпоступившего товара должно быть больше 0.';
	END IF;
	
	IF (new.deliveryDate IS NULL) 
	  THEN new.deliveryDate = now();
	END IF;
END;
$$ LANGUAGE plpgsql;

/*
Первый триггер - на таблицу товары на складе.
*/
CREATE TRIGGER checkStore
  BEFORE INSERT OR UPDATE ON Goodsonstorage
    FOR EACH ROW
      EXECUTE PROCEDURE doCheking();
      
/*
Таблица-архив для реализовавшихся товаров.
*/ 
CREATE TABLE archivGoods(
	article character(10) not null,
	dataDelivery DATE,
	deliveryNumber numeric(5) not null,
	provider numeric(5)
); 

/*
Функция для триггера - перенесение в архив.
*/ 
CREATE OR REPLACE FUNCTION  doArchive ()  RETURNS  TRIGGER  AS $$ 
BEGIN
	IF (NEW.quantityOfReceivedProduct - NEW.remainderOfGoods = 0) then
    	INSERT INTO archivGoods
    	VALUES(old.articleNumberOfGoods, old.deliveryDate, old.deliveryNumber, old.provider);
	END IF;
END;
$$ LANGUAGE plpgsql;

/*
Второй триггер на создание архива реализовавшихся товаров.
*/ 
CREATE TRIGGER setArchiv
   AFTER UPDATE OR INSERT ON Goodsonstorage
    FOR EACH ROW
      EXECUTE PROCEDURE doArchive();
