/* 
Создание функции для сравнения дат, что первая меньше второй.
На вход - две даты. На выход - сообщение.
Если условие выполняется - возвращается количество дней между датами.
Иначе возвращается -1.
*/
CREATE OR REPLACE FUNCTION dataCheck(dataFirst DATE, dataSecond DATE) RETURNS integer as $dataCheck$
DECLARE
  dataCheck integer;  
BEGIN
  IF (dataSecond-dataFirst>=0) THEN
    RETURN(dataSecond-dataFirst);
  ELSE
    RETURN(-1);
  END if;
END;
$dataCheck$ language PLPGSQL;

/* 
Вызов функции для сравнения дат
*/
select * from dataCheck('01.03.2000','02.03.2001'); 

/* 
Создание таблицы для отчета о товарах.
Переменные - название товара, единицы измерения, коливество поступившего товара, количество реализованного товара.
*/
CREATE TABLE otchet(
	nameOfProduct varchar(10),
	unitMesure varchar(4),
	numbersOfGoods integer,
	numbersOfWasGoods integer
);

/*
Создание функции для создания отчета о передвижении товара.
На вход - курсор для вывода товара, суммарное количества поставленного и реализованного товара.
На выход - курсор.
Сначала очищаем таблицу для отчета. 
Вторую дату на null значение проверяем.
Проверяем разницу дат, при неверном условии - исключение. Иначе, втавляем данные в таблицу отчет и открываем курсор/отправляем курсор.
*/
CREATE OR REPLACE FUNCTION makeOtchet(refCursorOtchet refcursor, dataFirst DATE, dataSecond DATE) RETURNS refcursor as $$
BEGIN
  DELETE FROM otchet;
  
  IF (dataSecond IS NULL) THEN 
    dataSecond = now();
  END IF;
  
  IF (dataCheck(dataFirst,dataSecond)=-1) THEN
    RAISE 'Начало периода больше окончания';
  ELSE
    INSERT INTO otchet(nameofproduct, unitmesure, numbersofgoods, numbersofwasgoods)
      SELECT things.name, things.unitsOfMeasurement, sum(thingsStore.quantityOfReceivedProduct), sum(thingsStore.quantityOfReceivedProduct-thingsStore.remainderofgoods) 
        FROM Goods as things, Goodsonstorage as thingsStore
          WHERE ((things.articlenumber = thingsStore.articlenumberofgoods) AND (thingsStore.deliverydate > '21.05.2001') AND (thingsStore.deliverydate < now())) 
            GROUP BY things.name, thingsStore.unitsOfMeasurement; 

    OPEN refCursorOtchet 
      SELECT things.name, things.unitsOfMeasurement, sum(thingsStore.quantityOfReceivedProduct), sum(thingsStore.quantityOfReceivedProduct-thingsStore.remainderofgoods) 
        FROM Goods as things, Goodsonstorage as thingsStore
          WHERE ((things.articlenumber = thingsStore.articlenumberofgoods) AND (thingsStore.deliverydate > '21.05.2001') AND (thingsStore.deliverydate < now())) 
            GROUP BY things.name, thingsStore.unitsOfMeasurement; 
              RETURN(refCursorOtchet);                                         
  END IF;
END;
$$ language PLPGSQL;

/*
Вызов функции
*/
select * FROM makeOtchet('getOtchet','21.05.2001','21.05.2002');
FETCH ALL IN "getOtchet";
