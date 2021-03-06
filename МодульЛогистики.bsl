Процедура ОбработкаОчередиФормированияРО() Экспорт
	
	ДокументовНаПоток = 30;
	КоличествоПотоков = 10;
	
	ТекстЗапроса = "ВЫБРАТЬ
	               |	ОчередьФормированияРО.ВидОперации КАК ВидОперации,
	               |	ОчередьФормированияРО.Документ КАК Документ,
	               |	ОчередьФормированияРО.ЧислоПопыток КАК ЧислоПопыток,
	               |	ОчередьФормированияРО.Документ.Дата КАК ДатаДокумента,
	               |	ОчередьФормированияРО.ОписаниеОшибки КАК ОписаниеОшибки,
	               |	ОчередьФормированияРО.ТаймШтамп КАК ТаймШтамп
	               |ИЗ
	               |	РегистрСведений.ОчередьФормированияРО КАК ОчередьФормированияРО
	               |ГДЕ
	               |	ОчередьФормированияРО.ВидОперации = ЗНАЧЕНИЕ(Перечисление.ВидыОперацийОчередиДокументов.ФормированиеРО)
	               |	И ОчередьФормированияРО.ЧислоПопыток <= 10
	               |
	               |УПОРЯДОЧИТЬ ПО
	               |	ТаймШтамп,
	               |	ДатаДокумента";
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Выборка = Запрос.Выполнить().Выбрать();
	
	// Если хотя бы одно задание завершено аварийно...
	Отбор = Новый Структура("ИмяМетода, Состояние", "МодульЛогистики.ОбработкаПотокаОчередиФормированияРО", СостояниеФоновогоЗадания.Активно);
	МассивАктивныхФЗ = ФоновыеЗадания.ПолучитьФоновыеЗадания(Отбор);
	Для Каждого ФЗ ИЗ МассивАктивныхФЗ Цикл
		ФЗ.Отменить();
	КонецЦикла;
	
	// 1. Разбиваем по потокам
	// 2. Выбираем записи и запускаем фоновые
	// 3. Ожидаем завершения
	
	НаборыДанных = Новый Соответствие;
	Сч = 0;
	Пока Выборка.Следующий() Цикл	// разбивка
		НомерПотока = Цел(Сч / ДокументовНаПоток);
		Если НомерПотока >= КоличествоПотоков Тогда
			Прервать;
		КонецЕсли;
		Если НаборыДанных[НомерПотока] = Неопределено Тогда
			НаборыДанных.Вставить(НомерПотока, Новый Массив);
		КонецЕсли;
		ТекНабор = НаборыДанных[НомерПотока];
		
		ТекНабор.Добавить(Выборка.Документ);
		Сч = Сч + 1;
	КонецЦикла;

	МассивФЗ = Новый Массив;
	Для Каждого Набор Из НаборыДанных Цикл // запуск
	
		Параметры = Новый Массив;
		Параметры.Добавить(Набор.Значение);
		ФЗ = ФоновыеЗадания.Выполнить("МодульЛогистики.ОбработкаПотокаОчередиФормированияРО", Параметры, "Номер потока " + Набор.Ключ);

		МассивФЗ.Добавить(ФЗ);
	КонецЦикла;
	
	Если МассивФЗ.Количество() > 0 Тогда
		ФоновыеЗадания.ОжидатьЗавершения(МассивФЗ, 60 * 5);
	КонецЕсли;
	
КонецПроцедуры
	
Процедура ОбработкаПотокаОчередиФормированияРО(МассивДокументов) Экспорт
	ТекстЗапроса = "ВЫБРАТЬ
	               |	ОчередьФормированияРО.ВидОперации КАК ВидОперации,
	               |	ОчередьФормированияРО.Документ КАК Документ,
	               |	ОчередьФормированияРО.ЧислоПопыток КАК ЧислоПопыток,
	               |	ОчередьФормированияРО.Документ.Дата КАК ДатаДокумента,
	               |	ОчередьФормированияРО.ОписаниеОшибки КАК ОписаниеОшибки,
	               |	ОчередьФормированияРО.ТаймШтамп КАК ТаймШтамп
	               |ИЗ
	               |	РегистрСведений.ОчередьФормированияРО КАК ОчередьФормированияРО
	               |ГДЕ
	               |	ОчередьФормированияРО.ВидОперации = ЗНАЧЕНИЕ(Перечисление.ВидыОперацийОчередиДокументов.ФормированиеРО)
	               |	И ОчередьФормированияРО.Документ В (&МассивДокументов)
	               |
	               |УПОРЯДОЧИТЬ ПО
	               |	ТаймШтамп,
	               |	ДатаДокумента";
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.Параметры.Вставить("МассивДокументов", МассивДокументов);
	Выборка = Запрос.Выполнить().Выбрать();
		
	Пока Выборка.Следующий() Цикл
		Если Выборка.ЧислоПопыток = 10 Тогда
			//Отправить письмо тех.поддержке.
			ТемаСообщения = "Ошибка при обработке документа в <Очереди формирования РО>!";
			ТекстСообщения = "Письмо отправлено автоматически. Ответ не требуется!"+Символы.ПС +"Число попыток при обработке документа в <Очереди формирования РО> превысило 10. Необходимо проверить документ, возможно его распровели, после добавления документа в очередь. Документ: " + Строка(Выборка.Документ);
			МодульРегламентныхЗаданий.ОтправкаСообщенияТехподдержке1С(ТекстСообщения, ТемаСообщения);
			УвеличитьСчетчикОчередиФормированияРО(Выборка.Документ);
			Продолжить;
		КонецЕсли;

		РОСформирован = СформироватьРасходник(Выборка.Документ);
		Если НЕ РОСформирован Тогда
			УвеличитьСчетчикОчередиФормированияРО(Выборка.Документ);
		КонецЕсли;
	КонецЦикла;
		
КонецПроцедуры

Функция СформироватьРасходник(Реализация)
	
	Если ТипЗнч(Реализация) = Тип("ДокументСсылка.ПеремещениеТоваров") Тогда
		ЗаказПокупателя = Реализация.ВнутреннийЗаказ;
	Иначе
		ЗаказПокупателя =  Реализация.Сделка;
	КонецЕсли;
	
	Успех = Ложь;
	Расходник = Неопределено;
	ВидОперации = Перечисления.ВидыОперацийОчередиДокументов.ФормированиеРО;
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
				   |	РасходныйОрдерНаТовары.Ссылка
				   |ИЗ
				   |	Документ.РасходныйОрдерНаТовары КАК РасходныйОрдерНаТовары
				   |ГДЕ
				   |	РасходныйОрдерНаТовары.ДокументПередачи = &Заказ
				   |	И РасходныйОрдерНаТовары.Проведен = Истина";
	Запрос.УстановитьПараметр("Заказ", Реализация);
	НачатьТранзакцию();
	Попытка
		
		Блокировка = Новый БлокировкаДанных;
		ЭлементБлокировки  = Блокировка.Добавить("РегистрСведений.ОчередьФормированияРО");
		ЭлементБлокировки.УстановитьЗначение("Документ", Реализация);
		ЭлементБлокировки.УстановитьЗначение("ВидОперации", ВидОперации);
		ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный; // !
		Блокировка.Заблокировать();
		
		Запись = РегистрыСведений.ОчередьФормированияРО.СоздатьМенеджерЗаписи();
		Запись.Документ = Реализация;
		Запись.ВидОперации = ВидОперации;
		Запись.Прочитать();
		Если Запись.Выбран() Тогда // !
			
			Рез = Запрос.Выполнить().Выбрать();
			Если Рез.Следующий() Тогда //РО создан
				Сообщить("Заказ перемещён в ""Готовые"".");
			Иначе  //РО не создан, нужно создать
		
				Расходник = Документы.РасходныйОрдерНаТовары.СоздатьДокумент();
				Блокировка 	= Новый БлокировкаДанных;
				Блок 		= Блокировка.Добавить("Документ.РасходныйОрдерНаТовары");
				Блок.Режим	= РежимБлокировкиДанных.Исключительный;
				Блок.УстановитьЗначение("ДокументПередачи", Реализация);
				Блокировка.Заблокировать();
				Расходник.Дата = ТекущаяДатаНаСервере();
				Если ТипЗнч(ЗаказПокупателя)=Тип("ДокументСсылка.ВнутреннийЗаказ") Тогда
					Расходник.ВидОперации 	= Перечисления.ВидыОперацийРасходныйОрдер.Перемещение;
					Расходник.Склад			= Реализация.СкладОтправитель;
				ИначеЕсли ТипЗнч(Реализация) = Тип("ДокументСсылка.ВозвратТоваровПоставщику")  Тогда
					Расходник.ВидОперации = Перечисления.ВидыОперацийРасходныйОрдер.ВозвратПоставщику;
				Иначе 
					Расходник.ВидОперации = Перечисления.ВидыОперацийРасходныйОрдер.РасходПоНакладной;
				КонецЕсли;
				ЗаполнениеДокументов.ЗаполнитьШапкуДокументаПоОснованию(Расходник, Реализация);
				Расходник.ДокументПередачи = Реализация;
				Расходник.ЗаполнитьТовары(Ложь);
				Расходник.Ответственный = ЗаказПокупателя.Ответственный;
				Если Не ТипЗнч(Реализация) = Тип("ДокументСсылка.ВозвратТоваровПоставщику")  Тогда
					Расходник.ВиртуальныйСклад = Реализация.ВиртуальныйСклад;
				КонецЕсли;
				Расходник.Записать(РежимЗаписиДокумента.Проведение); 
				УправлениеСтатусами.ОбновитьСтатусРеализации(Реализация, Перечисления.СтатусЗаказа.Собран);
			КонецЕсли;
			УдалитьЗаписьИзОчередиФормированияРО(Реализация);
			Успех = Истина;
		КонецЕсли;
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ТекстОписаниеОшибки = ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("Создание РО", УровеньЖурналаРегистрации.Ошибка, , Реализация, ТекстОписаниеОшибки);
		Успех = Ложь;
	Конецпопытки;
	
	Возврат Успех;
КонецФункции
