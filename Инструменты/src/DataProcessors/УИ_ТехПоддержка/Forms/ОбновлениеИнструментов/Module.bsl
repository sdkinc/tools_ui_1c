&НаКлиенте
Процедура Обновить(Команда)
	РезультатьОбновления=РезультатОбновленияНаСервере();

	Если РезультатьОбновления=Неопределено Тогда
		ПоказатьВопрос(Новый ОписаниеОповещения("ОбновитьЗавершение", ЭтотОбъект),
			"Обновление успешно применено. Для использования изменений нужно перезапустить сеанс. Перезапустить?",
			РежимДиалогаВопрос.ДаНет);
	Иначе
		УИ_ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка применения обновления " + РезультатьОбновления);
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ОбновитьЗавершение(Результат, ДополнительныеПараметры) Экспорт
	Если Результат = КодВозвратаДиалога.Нет Тогда
		Возврат;
	КонецЕсли;

	ЗавершитьРаботуСистемы(Ложь, Истина);
КонецПроцедуры

&НаСервере
Функция РезультатОбновленияНаСервере()
	Ответ=УИ_КоннекторHTTP.Get(URLАктуальногоРелиза);

	Если Ответ.КодСостояния > 300 Тогда
		Возврат "Не удалось скачать файл обновления с сервера";
	КонецЕсли;

	ДвоичныеДанные=Ответ.Тело;

	Если ТипЗнч(ДвоичныеДанные) <> Тип("ДвоичныеДанные") Тогда
		Возврат "Неправильный формат файла облновления";
	КонецЕсли;

	Отбор = Новый Структура;
	Отбор.Вставить("Имя", "УниверсальныеИнструменты");

	НайденныеРасширения = РасширенияКонфигурации.Получить(Отбор);

	Если НайденныеРасширения.Количество() = 0 Тогда
		Возврат "Не обнаружено расширение Универсальные инструменты";
	КонецЕсли;

	НашеРасширение = НайденныеРасширения[0];
	
	// Проверим возможность применения расширения

	РезультатПроверки=НашеРасширение.ПроверитьВозможностьПрименения(ДвоичныеДанные, Ложь);

	Если РезультатПроверки.Количество() > 0 Тогда
		СообщениеОбОшибках="";
		Для Каждого ИнформацияОПроблемеПримененияРасширенияКонфигурации Из РезультатПроверки Цикл
			СообщениеОбОшибках=СообщениеОбОшибках+?(ЗначениеЗаполнено(СообщениеОбОшибках),Символы.ПС,"")+"Ошибка применения расширения "
				+ ИнформацияОПроблемеПримененияРасширенияКонфигурации.Описание;
		КонецЦикла;

		Возврат СообщениеОбОшибках;
	КонецЕсли;

	РезультатОбновления=Неопределено;
	Попытка
		НашеРасширение.Записать(ДвоичныеДанные);
	Исключение
		РезультатОбновления=ОписаниеОшибки();
	КонецПопытки;

	Возврат РезультатОбновления;

КонецФункции

&НаСервере
Процедура ЗаполнитьТекущуюВерсию()
	Отбор = Новый Структура;
	Отбор.Вставить("Имя", "УниверсальныеИнструменты");

	НайденныеРасширения = РасширенияКонфигурации.Получить(Отбор);

	Если НайденныеРасширения.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;

	НашеРасширение = НайденныеРасширения[0];
	ТекущаяВерсия = НашеРасширение.Версия;
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьАктуальнуюВерсиюИОписаниеИзменений()
//Получаем список всех релизов
	АдресЗапроса = "https://api.github.com/repos/cpr1c/tools_ui_1c/releases";

	МассивРелизов = УИ_КоннекторHTTP.GetJson(АдресЗапроса);

	МаксимальныйРелиз = "0.0.0";
	СоответствиеОписанияРелизов = Новый Соответствие;

	Для Каждого ТекРелиз Из МассивРелизов Цикл
		ВерсияТекРелиза = СтрЗаменить(ТекРелиз["tag_name"], "v", "");

		Если УИ_ОбщегоНазначенияКлиентСервер.СравнитьВерсииБезНомераСборки(ВерсияТекРелиза, ТекущаяВерсия) > 0 Тогда
			СоответствиеОписанияРелизов.Вставить(ВерсияТекРелиза, ТекРелиз);
		КонецЕсли;

		Если УИ_ОбщегоНазначенияКлиентСервер.СравнитьВерсииБезНомераСборки(ВерсияТекРелиза, МаксимальныйРелиз) <= 0 Тогда
			Продолжить;
		КонецЕсли;

		МаксимальныйРелиз = ВерсияТекРелиза;
		ВложенияРелиза = ТекРелиз["assets"];
		Если ВложенияРелиза = Неопределено Тогда
			URLАктуальногоРелиза = "";
		Иначе
			Для Каждого ТекВложение Из ВложенияРелиза Цикл
				ИмяФайлаРелиза = ТекВложение["name"];

				Если СтрНайти(НРег(ИмяФайлаРелиза), "cfe") = 0 Тогда
					Продолжить;
				КонецЕсли;

				URLАктуальногоРелиза=ТекВложение["browser_download_url"];
				Прервать;
			КонецЦикла;
		КонецЕсли;
	КонецЦикла;

	АктуальнаяВерсия = МаксимальныйРелиз;

	ОписаниеИзменений = "";
	Для Каждого РелизОписания Из СоответствиеОписанияРелизов Цикл
		ОписаниеИзменений = ОписаниеИзменений + РелизОписания.Ключ + Символы.ПС;
		ОписаниеИзменений = ОписаниеИзменений + РелизОписания.Значение["body"] + Символы.ПС;
	КонецЦикла;
КонецПроцедуры

&НаСервере
Процедура УстановитьНеобходимостьОбновления()
	Если УИ_ОбщегоНазначенияКлиентСервер.СравнитьВерсииБезНомераСборки(АктуальнаяВерсия, ТекущаяВерсия) > 0 Тогда
		НеобходимостьОбновления = Истина;
	КонецЕсли;

	Элементы.ФормаОбновить.Видимость = НеобходимостьОбновления;
	Элементы.ОписаниеИзменений.Видимость = НеобходимостьОбновления;
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	ЗаполнитьТекущуюВерсию();
	ЗаполнитьАктуальнуюВерсиюИОписаниеИзменений();
	УстановитьНеобходимостьОбновления();
КонецПроцедуры