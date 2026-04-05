#!/usr/bin/env python3
"""Merge new i18n keys into ru/kk/en JSON files."""
import json, sys, os

BASE = os.path.join(os.path.dirname(__file__), '..', 'data', 'i18n')

NEW_KEYS = {
# ─── LOGIC V2 SHARED ───────────────────────────────────────────────────────
"logic.v2.common.btn_back":     {"ru":"НАЗАД","kk":"АРТҚА","en":"BACK"},
"logic.v2.common.btn_hint":     {"ru":"ПОДСКАЗКА","kk":"КЕҢЕС","en":"HINT"},
"logic.v2.common.btn_confirm":  {"ru":"ПОДТВЕРДИТЬ","kk":"РАСТАУ","en":"CONFIRM"},
"logic.v2.common.btn_exit":     {"ru":"ВЫХОД","kk":"ШЫҒУ","en":"EXIT"},
"logic.v2.common.complete_title":{"ru":"РАССЛЕДОВАНИЕ ЗАВЕРШЕНО","kk":"ТЕРГЕУ АЯҚТАЛДЫ","en":"INVESTIGATION COMPLETE"},

# ─── LOGIC V2 A ─────────────────────────────────────────────────────────────
"logic.v2.a.title":       {"ru":"ДОПРОС: ПРОТОКОЛ","kk":"ЖАУАП АЛУ: ХАТТАМА","en":"INTERROGATION: PROTOCOL"},
"logic.v2.a.operation":   {"ru":"ОПЕРАЦИЯ: {gate}","kk":"ОПЕРАЦИЯ: {gate}","en":"OPERATION: {gate}"},
"logic.v2.a.intro":       {
  "ru":"ЗАДАНИЕ: Заполни таблицу истинности.\n\nНажимайте на ячейки «?» чтобы переключить: ? → 0 → 1 → ?\nЗатем нажмите ПОДТВЕРДИТЬ.\n\nПОДСКАЗКА откроет одну правильную ячейку.",
  "kk":"ТАПСЫРМА: Шындық кестесін толтырыңыз.\n\n«?» ұяшықтарын басып ауыстырыңыз: ? → 0 → 1 → ?\nСоңынан РАСТАУ басыңыз.\n\nКЕҢЕС бір дұрыс ұяшықты ашады.",
  "en":"TASK: Fill the truth table.\n\nTap cells with '?' to toggle: ? → 0 → 1 → ?\nThen press CONFIRM.\n\nHINT will reveal one correct cell."
},
"logic.v2.a.fill_all":    {"ru":"Заполните все ячейки с «?»","kk":"Барлық «?» ұяшықтарын толтырыңыз","en":"Fill all cells marked '?'"},
"logic.v2.a.wrong_cells": {"ru":"Есть ошибки — попробуй снова","kk":"Қателер бар — қайталап көріңіз","en":"Some errors — try again"},
"logic.v2.a.complete_body":{"ru":"Все {n} протокола изучены.\nТаблицы истинности — основа любого логического анализа.","kk":"Барлық {n} хаттама зерттелді.\nШындық кестесі кез-келген логикалық талдаудың негізі.","en":"All {n} protocols studied.\nTruth tables are the foundation of logic analysis."},

"logic.v2.a.A_01.gate_label":{"ru":"AND (И)","kk":"AND (ЖӘНЕ)","en":"AND"},
"logic.v2.a.A_01.story":{"ru":"Двигатель заводится, только если КЛЮЧ вставлен И СТАРТ нажат.","kk":"Қозғалтқыш КІЛТ салынған ЖӘНЕ СТАРТ басылған жағдайда ғана іске қосылады.","en":"Engine starts only if KEY is inserted AND START is pressed."},
"logic.v2.a.A_01.explain":{"ru":"AND даёт 1 только когда ОБА входа равны 1.\n0 AND 0 = 0,  0 AND 1 = 0,  1 AND 0 = 0,  1 AND 1 = 1","kk":"AND тек ЕКІ кіріс те 1-ге тең болғанда ғана 1 береді.\n0 AND 0 = 0,  0 AND 1 = 0,  1 AND 0 = 0,  1 AND 1 = 1","en":"AND gives 1 only when BOTH inputs are 1.\n0 AND 0=0, 0 AND 1=0, 1 AND 0=0, 1 AND 1=1"},

"logic.v2.a.A_02.gate_label":{"ru":"OR (ИЛИ)","kk":"OR (НЕМЕСЕ)","en":"OR"},
"logic.v2.a.A_02.story":{"ru":"Тревога срабатывает, если обнаружен ДЫМ или ДВИЖЕНИЕ.","kk":"ТҮТІН немесе ҚОЗҒАЛЫС анықталса, дабыл іске қосылады.","en":"Alarm triggers if SMOKE or MOTION is detected."},
"logic.v2.a.A_02.explain":{"ru":"OR даёт 1 когда ХОТЯ БЫ ОДИН вход равен 1.\n0 OR 0=0, 0 OR 1=1, 1 OR 0=1, 1 OR 1=1","kk":"OR кем дегенде БІР кіріс 1 болғанда 1 береді.\n0 OR 0=0, 0 OR 1=1, 1 OR 0=1, 1 OR 1=1","en":"OR gives 1 when AT LEAST ONE input is 1.\n0 OR 0=0, 0 OR 1=1, 1 OR 0=1, 1 OR 1=1"},

"logic.v2.a.A_03.gate_label":{"ru":"NOT (НЕ)","kk":"NOT (ЕМЕС)","en":"NOT"},
"logic.v2.a.A_03.story":{"ru":"Инвертор: если сигнал есть — на выходе нет, и наоборот.","kk":"Инвертор: сигнал бар болса — шығыста жоқ, керісінше де солай.","en":"Inverter: if signal is present — output is absent, and vice versa."},
"logic.v2.a.A_03.explain":{"ru":"NOT инвертирует входной сигнал.\nNOT 0 = 1,  NOT 1 = 0","kk":"NOT кіріс сигналын инвертирлейді.\nNOT 0 = 1,  NOT 1 = 0","en":"NOT inverts the input signal.\nNOT 0 = 1,  NOT 1 = 0"},

"logic.v2.a.A_04.gate_label":{"ru":"XOR (Искл. ИЛИ)","kk":"XOR (Айрықша НЕМЕСЕ)","en":"XOR (Exclusive OR)"},
"logic.v2.a.A_04.story":{"ru":"Лампа переключается, когда ОДИН из выключателей изменён, но не оба.","kk":"Шам БІР ауыстырғыш өзгергенде ауысады, бірақ екеуі бірдей емес.","en":"Lamp toggles when ONE switch changes, but not both."},
"logic.v2.a.A_04.explain":{"ru":"XOR даёт 1 когда входы РАЗЛИЧНЫ.\n0 XOR 0=0, 0 XOR 1=1, 1 XOR 0=1, 1 XOR 1=0","kk":"XOR кірістер ӘРТҮРЛІ болғанда 1 береді.\n0 XOR 0=0, 0 XOR 1=1, 1 XOR 0=1, 1 XOR 1=0","en":"XOR gives 1 when inputs DIFFER.\n0 XOR 0=0, 0 XOR 1=1, 1 XOR 0=1, 1 XOR 1=0"},

"logic.v2.a.A_05.gate_label":{"ru":"NAND (И-НЕ)","kk":"NAND (ЖӘНЕ-ЕМЕС)","en":"NAND"},
"logic.v2.a.A_05.story":{"ru":"Защита отключается, только если ОБА ключа одновременно повёрнуты.","kk":"Қорғаныс ЕКІ кілт бір уақытта бұрылғанда ғана өшеді.","en":"Protection disables only if BOTH keys are turned simultaneously."},
"logic.v2.a.A_05.explain":{"ru":"NAND = NOT(AND). Даёт 0 только когда ОБА входа = 1.\nВо всех остальных случаях — 1.","kk":"NAND = NOT(AND). Тек ЕКІ кіріс те 1 болғанда 0 береді.\nҚалған барлық жағдайда — 1.","en":"NAND = NOT(AND). Gives 0 only when BOTH inputs = 1.\nAll other cases — 1."},

"logic.v2.a.A_06.gate_label":{"ru":"NOR (ИЛИ-НЕ)","kk":"NOR (НЕМЕСЕ-ЕМЕС)","en":"NOR"},
"logic.v2.a.A_06.story":{"ru":"Система в покое, только когда НИ ОДИН датчик не активен.","kk":"Жүйе тек ЕШ БІР датчик белсенді болмағанда ғана тыныштықта.","en":"System is idle only when NO sensor is active."},
"logic.v2.a.A_06.explain":{"ru":"NOR = NOT(OR). Даёт 1 только когда ОБА входа = 0.\nХотя бы один 1 → выход 0.","kk":"NOR = NOT(OR). Тек ЕКІ кіріс те 0 болғанда 1 береді.\nКемінде бір 1 → шығыс 0.","en":"NOR = NOT(OR). Gives 1 only when BOTH inputs = 0.\nAny 1 → output 0."},

"logic.v2.a.A_07.gate_label":{"ru":"AND (И)","kk":"AND (ЖӘНЕ)","en":"AND"},
"logic.v2.a.A_07.story":{"ru":"Доступ открыт: КАРТА приложена И ПИН-код верный.","kk":"Кіру ашық: КАРТА тіркелген ЖӘНЕ ПИН-код дұрыс.","en":"Access granted: CARD applied AND PIN correct."},
"logic.v2.a.A_07.explain":{"ru":"AND: оба условия должны выполняться одновременно.","kk":"AND: екі шарт та бір уақытта орындалуы керек.","en":"AND: both conditions must be true simultaneously."},

"logic.v2.a.A_08.gate_label":{"ru":"OR (ИЛИ)","kk":"OR (НЕМЕСЕ)","en":"OR"},
"logic.v2.a.A_08.story":{"ru":"Уведомление: пришёл ЗВОНОК или СООБЩЕНИЕ.","kk":"Хабарлама: ҚОҢЫРАУ немесе ХАБАР келді.","en":"Notification: CALL or MESSAGE received."},
"logic.v2.a.A_08.explain":{"ru":"OR: достаточно одного из условий.","kk":"OR: бір шарттың орындалуы жеткілікті.","en":"OR: one condition is sufficient."},

"logic.v2.a.A_09.gate_label":{"ru":"XOR (Искл. ИЛИ)","kk":"XOR (Айрықша НЕМЕСЕ)","en":"XOR (Exclusive OR)"},
"logic.v2.a.A_09.story":{"ru":"Режим переключения: нажми ОДИН переключатель, но не оба.","kk":"Ауыстыру режимі: БІР ауыстырғышты басыңыз, бірақ екеуін емес.","en":"Toggle mode: press ONE switch, but not both."},
"logic.v2.a.A_09.explain":{"ru":"XOR: входы должны быть разными. Одинаковые → 0.","kk":"XOR: кірістер ӘРТҮРЛІ болуы керек. Бірдей болса → 0.","en":"XOR: inputs must differ. Same inputs → 0."},

"logic.v2.a.A_10.gate_label":{"ru":"NAND (И-НЕ)","kk":"NAND (ЖӘНЕ-ЕМЕС)","en":"NAND"},
"logic.v2.a.A_10.story":{"ru":"Аварийная блокировка: срабатывает, если НЕ все системы активны.","kk":"Апаттық құлыптау: барлық жүйелер бір уақытта белсенді БОЛМАСА іске қосылады.","en":"Emergency lock: triggers if NOT all systems are active."},
"logic.v2.a.A_10.explain":{"ru":"NAND: 0 только при обоих 1, иначе всегда 1.","kk":"NAND: тек екеуі де 1 болғанда 0, әйтпесе әрқашан 1.","en":"NAND: 0 only when both are 1, otherwise always 1."},

# ─── LOGIC V2 B ─────────────────────────────────────────────────────────────
"logic.v2.b.title":       {"ru":"ДОПРОС: ВЫЧИСЛЕНИЕ","kk":"ЖАУАП АЛУ: ЕСЕПТЕУ","en":"INTERROGATION: EVALUATE"},
"logic.v2.b.expr_title":  {"ru":"ВЫРАЖЕНИЕ:","kk":"ӨРНЕК:","en":"EXPRESSION:"},
"logic.v2.b.val_title":   {"ru":"ЗНАЧЕНИЯ:","kk":"МӘНДЕР:","en":"VALUES:"},
"logic.v2.b.q_lbl":       {"ru":"ЧТО ПОЛУЧИТСЯ?","kk":"НЕ ШЫҒАДЫ?","en":"WHAT IS THE RESULT?"},
"logic.v2.b.intro":       {
  "ru":"ЗАДАНИЕ: Вычисли результат логического выражения.\n\nПодставь данные значения A, B, C в выражение.\nВыбери ответ: 0 или 1, затем нажми ПОДТВЕРДИТЬ.\n\nПОДСКАЗКА покажет первый шаг вычисления.",
  "kk":"ТАПСЫРМА: Логикалық өрнектің нәтижесін есептеңіз.\n\nА, В, С мәндерін өрнекке қойыңыз.\nЖауапты таңдаңыз: 0 немесе 1, содан кейін РАСТАУ басыңыз.\n\nКЕҢЕС есептеудің бірінші қадамын көрсетеді.",
  "en":"TASK: Calculate the result of the logical expression.\n\nSubstitute given values A, B, C into the expression.\nChoose answer: 0 or 1, then press CONFIRM.\n\nHINT shows the first calculation step."
},
"logic.v2.b.select_err":  {"ru":"Выберите 0 или 1","kk":"0 немесе 1 таңдаңыз","en":"Select 0 or 1"},
"logic.v2.b.wrong":       {"ru":"Неверно — проверь шаги вычисления","kk":"Қате — есептеу қадамдарын тексеріңіз","en":"Wrong — check the calculation steps"},
"logic.v2.b.complete_body":{"ru":"Все {n} вычисления выполнены.\nВычисление логических выражений — ключ к анализу схем.","kk":"Барлық {n} есептеу орындалды.\nЛогикалық өрнектерді есептеу схемаларды талдаудың кілті.","en":"All {n} calculations done.\nEvaluating logic expressions is key to circuit analysis."},

"logic.v2.b.B_01.story":{"ru":"Оба датчика активны. Что покажет система?","kk":"Екі датчик та белсенді. Жүйе не көрсетеді?","en":"Both sensors are active. What will the system show?"},
"logic.v2.b.B_02.story":{"ru":"Один из каналов передаёт сигнал.","kk":"Арналардың бірі сигнал беріп жатыр.","en":"One of the channels is transmitting a signal."},
"logic.v2.b.B_03.story":{"ru":"Инвертор получил сигнал.","kk":"Инвертор сигнал алды.","en":"Inverter received a signal."},
"logic.v2.b.B_04.story":{"ru":"Оба переключателя в одном положении.","kk":"Екі ауыстырғыш та бір күйде тұр.","en":"Both switches are in the same position."},
"logic.v2.b.B_05.story":{"ru":"Основной канал активен, помеха отключена.","kk":"Негізгі арна белсенді, кедергі өшірілген.","en":"Main channel is active, interference is disabled."},
"logic.v2.b.B_06.story":{"ru":"Фильтр активен, но входные данные пусты.","kk":"Сүзгі белсенді, бірақ кіріс деректері бос.","en":"Filter is active but input data is empty."},
"logic.v2.b.B_07.story":{"ru":"Инвертированный сигнал A и прямой B.","kk":"A-ның инвертирленген сигналы және тікелей B.","en":"Inverted signal A and direct signal B."},
"logic.v2.b.B_08.story":{"ru":"Два подканала: совпадение A/B и инверсия C.","kk":"Екі қосалқы арна: A/B сәйкестігі және C инверсиясы.","en":"Two sub-channels: A/B match and C inversion."},
"logic.v2.b.B_09.story":{"ru":"Хотя бы один вход и отсутствие блокировки.","kk":"Кемінде бір кіріс және бұғаттаудың жоқтығы.","en":"At least one input and absence of blocking."},
"logic.v2.b.B_10.story":{"ru":"Отрицание совпадения с запасным каналом C.","kk":"C резервтік арнасымен сәйкестікті теріске шығару.","en":"Negation of match combined with backup channel C."},

# ─── LOGIC V2 C ─────────────────────────────────────────────────────────────
"logic.v2.c.title":        {"ru":"ДОПРОС: УПРОЩЕНИЕ","kk":"ЖАУАП АЛУ: ЖЕҢІЛДЕТУ","en":"INTERROGATION: SIMPLIFY"},
"logic.v2.c.orig_title":   {"ru":"ИСХОДНОЕ ВЫРАЖЕНИЕ:","kk":"БАСТАПҚЫ ӨРНЕК:","en":"ORIGINAL EXPRESSION:"},
"logic.v2.c.law_prefix":   {"ru":"ЗАКОН:","kk":"ЗАҢ:","en":"LAW:"},
"logic.v2.c.opts_header":  {"ru":"ВЫБЕРИТЕ УПРОЩЁННЫЙ ВАРИАНТ:","kk":"ЖЕҢІЛДЕТІЛГЕН НҰСҚАНЫ ТАҢДАҢЫЗ:","en":"CHOOSE THE SIMPLIFIED FORM:"},
"logic.v2.c.intro":        {
  "ru":"ЗАДАНИЕ: Упрости логическое выражение.\n\nПрименив указанный закон, выбери правильный вариант из трёх.\n\nПОДСКАЗКА покажет как применяется закон пошагово.",
  "kk":"ТАПСЫРМА: Логикалық өрнекті жеңілдетіңіз.\n\nКөрсетілген заңды қолданып, үштен дұрыс нұсқаны таңдаңыз.\n\nКЕҢЕС заңның қадамдық қолданылуын көрсетеді.",
  "en":"TASK: Simplify the logical expression.\n\nApply the given law and choose the correct form from three options.\n\nHINT shows how the law applies step by step."
},
"logic.v2.c.hint_prefix":  {"ru":"Подсказка: {hint}\n\nПравило: {law}","kk":"Кеңес: {hint}\n\nЕреже: {law}","en":"Hint: {hint}\n\nRule: {law}"},
"logic.v2.c.no_selection": {"ru":"Выберите вариант ответа","kk":"Жауап нұсқасын таңдаңыз","en":"Select an answer option"},
"logic.v2.c.wrong":        {"ru":"Неверно — изучи объяснение","kk":"Қате — түсіндірмені оқыңыз","en":"Wrong — read the explanation"},
"logic.v2.c.complete_body":{"ru":"Все {n} законов применены.\nАлгебра логики — основа оптимизации цифровых схем.","kk":"Барлық {n} заң қолданылды.\nЛогика алгебрасы цифрлық схемаларды оңтайландырудың негізі.","en":"All {n} laws applied.\nBoolean algebra is the foundation of digital circuit optimization."},

"logic.v2.c.C_01.law":      {"ru":"Дистрибутивность","kk":"Дистрибутивтілік","en":"Distributivity"},
"logic.v2.c.C_01.law_hint": {"ru":"Вынести общий множитель A за скобки","kk":"A ортақ көбейткішін жақшадан шығарыңыз","en":"Factor out common A"},
"logic.v2.c.C_01.explanation":{"ru":"(A∧B)∨(A∧C) = A∧(B∨C)\n\nОбщий множитель A выносится за скобки.\nAND и OR меняются местами внутри скобок.","kk":"(A∧B)∨(A∧C) = A∧(B∨C)\n\nA ортақ көбейткіші жақшадан шығарылады.\nAND және OR жақша ішінде орын ауыстырады.","en":"(A∧B)∨(A∧C) = A∧(B∨C)\n\nFactor out common A.\nAND and OR swap inside the brackets."},

"logic.v2.c.C_02.law":      {"ru":"Дистрибутивность","kk":"Дистрибутивтілік","en":"Distributivity"},
"logic.v2.c.C_02.law_hint": {"ru":"Вынести общее слагаемое A","kk":"A ортақ қосылғышын шығарыңыз","en":"Factor out common A"},
"logic.v2.c.C_02.explanation":{"ru":"(A∨B)∧(A∨C) = A∨(B∧C)\n\nОбратная дистрибутивность: OR выносится.\nOR и AND меняются местами.","kk":"(A∨B)∧(A∨C) = A∨(B∧C)\n\nКері дистрибутивтілік: OR шығарылады.\nOR және AND орын ауыстырады.","en":"(A∨B)∧(A∨C) = A∨(B∧C)\n\nReverse distributivity: OR factors out.\nOR and AND swap places."},

"logic.v2.c.C_03.law":      {"ru":"Поглощение","kk":"Сіңіру","en":"Absorption"},
"logic.v2.c.C_03.law_hint": {"ru":"A поглощает A AND B","kk":"A элементі A AND B-ні сіңіреді","en":"A absorbs A AND B"},
"logic.v2.c.C_03.explanation":{"ru":"A∨(A∧B) = A\n\nЕсли A=1: всё = 1 независимо от B.\nЕсли A=0: A∧B=0, и 0∨0=0 = A.\nРезультат всегда равен A.","kk":"A∨(A∧B) = A\n\nA=1 болса: бәрі = 1, B-ге тәуелсіз.\nA=0 болса: A∧B=0, және 0∨0=0 = A.\nНәтиже әрқашан A-ға тең.","en":"A∨(A∧B) = A\n\nIf A=1: everything = 1 regardless of B.\nIf A=0: A∧B=0, and 0∨0=0 = A.\nResult always equals A."},

"logic.v2.c.C_04.law":      {"ru":"Поглощение","kk":"Сіңіру","en":"Absorption"},
"logic.v2.c.C_04.law_hint": {"ru":"A поглощает A OR B","kk":"A элементі A OR B-ні сіңіреді","en":"A absorbs A OR B"},
"logic.v2.c.C_04.explanation":{"ru":"A∧(A∨B) = A\n\nЕсли A=1: 1∧(1∨B)=1∧1=1=A.\nЕсли A=0: 0∧(0∨B)=0=A.\nОбратное поглощение.","kk":"A∧(A∨B) = A\n\nA=1 болса: 1∧(1∨B)=1∧1=1=A.\nA=0 болса: 0∧(0∨B)=0=A.\nКері сіңіру.","en":"A∧(A∨B) = A\n\nIf A=1: 1∧(1∨B)=1∧1=1=A.\nIf A=0: 0∧(0∨B)=0=A.\nReverse absorption."},

"logic.v2.c.C_05.law":      {"ru":"Де Морган","kk":"Де Морган","en":"De Morgan"},
"logic.v2.c.C_05.law_hint": {"ru":"NOT перед AND: AND→OR, каждый вход инвертировать","kk":"AND алдындағы NOT: AND→OR, әр кірісті инвертирлеу","en":"NOT before AND: AND→OR, invert each input"},
"logic.v2.c.C_05.explanation":{"ru":"¬(A∧B) = ¬A∨¬B\n\nПравило Де Моргана для AND:\n1) AND меняется на OR\n2) Каждый вход инвертируется","kk":"¬(A∧B) = ¬A∨¬B\n\nAND үшін Де Морган ережесі:\n1) AND OR-ға ауысады\n2) Әр кіріс инвертирленеді","en":"¬(A∧B) = ¬A∨¬B\n\nDe Morgan's law for AND:\n1) AND changes to OR\n2) Each input is inverted"},

"logic.v2.c.C_06.law":      {"ru":"Де Морган","kk":"Де Морган","en":"De Morgan"},
"logic.v2.c.C_06.law_hint": {"ru":"NOT перед OR: OR→AND, каждый вход инвертировать","kk":"OR алдындағы NOT: OR→AND, әр кірісті инвертирлеу","en":"NOT before OR: OR→AND, invert each input"},
"logic.v2.c.C_06.explanation":{"ru":"¬(A∨B) = ¬A∧¬B\n\nПравило Де Моргана для OR:\n1) OR меняется на AND\n2) Каждый вход инвертируется","kk":"¬(A∨B) = ¬A∧¬B\n\nOR үшін Де Морган ережесі:\n1) OR AND-ға ауысады\n2) Әр кіріс инвертирленеді","en":"¬(A∨B) = ¬A∧¬B\n\nDe Morgan's law for OR:\n1) OR changes to AND\n2) Each input is inverted"},

"logic.v2.c.C_07.law":      {"ru":"Двойное отрицание","kk":"Қос терістеу","en":"Double Negation"},
"logic.v2.c.C_07.law_hint": {"ru":"Два NOT отменяют друг друга","kk":"Екі NOT бірін-бірі жояды","en":"Two NOTs cancel each other"},
"logic.v2.c.C_07.explanation":{"ru":"¬(¬A) = A\n\nДва отрицания отменяются.\nNOT NOT A = A","kk":"¬(¬A) = A\n\nЕкі терістеу бір-бірін жояды.\nNOT NOT A = A","en":"¬(¬A) = A\n\nTwo negations cancel out.\nNOT NOT A = A"},

"logic.v2.c.C_08.law":      {"ru":"Двойное отрицание","kk":"Қос терістеу","en":"Double Negation"},
"logic.v2.c.C_08.law_hint": {"ru":"Два внешних NOT убрать","kk":"Сыртқы екі NOT-ты алыңыз","en":"Remove two outer NOTs"},
"logic.v2.c.C_08.explanation":{"ru":"¬(¬(A∨B)) = A∨B\n\nВнешние два NOT взаимно отменяются.\nВнутреннее выражение A∨B остаётся.","kk":"¬(¬(A∨B)) = A∨B\n\nСыртқы екі NOT өзара жойылады.\nІшкі A∨B өрнегі қалады.","en":"¬(¬(A∨B)) = A∨B\n\nTwo outer NOTs cancel each other.\nInner expression A∨B remains."},

# ─── LEARN SELECT LESSONS ───────────────────────────────────────────────────
"ui.learn_select.group.number":  {"ru":"⬛ Системы счисления","kk":"⬛ Санау жүйелері","en":"⬛ Number Systems"},
"ui.learn_select.group.logic":   {"ru":"🔀 Логика","kk":"🔀 Логика","en":"🔀 Logic"},
"ui.learn_select.group.networks":{"ru":"🌐 Сети","kk":"🌐 Желілер","en":"🌐 Networks"},
"ui.learn_select.group.algo":    {"ru":"🗺️ Алгоритмы","kk":"🗺️ Алгоритмдер","en":"🗺️ Algorithms"},
"ui.learn_select.group.encoding":{"ru":"📡 Кодирование","kk":"📡 Кодтау","en":"📡 Encoding"},

"ui.learn_select.lesson.bin_basics.title":    {"ru":"Биты и байты","kk":"Биттер мен байттар","en":"Bits and Bytes"},
"ui.learn_select.lesson.bin_basics.subtitle": {"ru":"Что такое бит, байт, степени двойки","kk":"Бит, байт, 2-нің дәреже дегеніміз не","en":"What is a bit, byte, powers of two"},
"ui.learn_select.lesson.bin_convert.title":   {"ru":"Двоичный перевод","kk":"Екілік аудару","en":"Binary Conversion"},
"ui.learn_select.lesson.bin_convert.subtitle":{"ru":"2→10 и 10→2, алгоритм деления","kk":"2→10 және 10→2, бөлу алгоритмі","en":"2→10 and 10→2, division algorithm"},
"ui.learn_select.lesson.hex_basics.title":    {"ru":"Шестнадцатеричная","kk":"Он алтылық","en":"Hexadecimal"},
"ui.learn_select.lesson.hex_basics.subtitle": {"ru":"Цифры 0-9 и A-F, HEX логика","kk":"0-9 және A-F сандары, HEX логикасы","en":"Digits 0-9 and A-F, HEX logic"},
"ui.learn_select.lesson.hex_convert.title":   {"ru":"Перевод HEX↔BIN↔DEC","kk":"HEX↔BIN↔DEC аудару","en":"HEX↔BIN↔DEC Conversion"},
"ui.learn_select.lesson.hex_convert.subtitle":{"ru":"Таблица перевода, практика","kk":"Аудару кестесі, тәжірибе","en":"Conversion table, practice"},
"ui.learn_select.lesson.xor_cipher.title":    {"ru":"XOR-шифрование","kk":"XOR-шифрлеу","en":"XOR Encryption"},
"ui.learn_select.lesson.xor_cipher.subtitle": {"ru":"Побитовая операция, ключ XOR","kk":"Биттік операция, XOR кілті","en":"Bitwise operation, XOR key"},

"ui.learn_select.lesson.logic_basic.title":    {"ru":"AND, OR, NOT","kk":"AND, OR, NOT","en":"AND, OR, NOT"},
"ui.learn_select.lesson.logic_basic.subtitle": {"ru":"Три базовых вентиля, таблицы","kk":"Үш негізгі вентиль, кестелер","en":"Three basic gates, tables"},
"ui.learn_select.lesson.logic_xor_nand.title": {"ru":"XOR, NAND, NOR","kk":"XOR, NAND, NOR","en":"XOR, NAND, NOR"},
"ui.learn_select.lesson.logic_xor_nand.subtitle":{"ru":"Производные вентили","kk":"Туынды вентильдер","en":"Derived gates"},
"ui.learn_select.lesson.logic_tables.title":   {"ru":"Таблицы истинности","kk":"Шындық кестелері","en":"Truth Tables"},
"ui.learn_select.lesson.logic_tables.subtitle":{"ru":"Составление для сложных выражений","kk":"Күрделі өрнектер үшін кесте құру","en":"Building for complex expressions"},
"ui.learn_select.lesson.logic_circuits.title": {"ru":"Логические схемы","kk":"Логикалық сызбалар","en":"Logic Circuits"},
"ui.learn_select.lesson.logic_circuits.subtitle":{"ru":"Комбинирование вентилей","kk":"Вентильдерді біріктіру","en":"Combining gates"},

"ui.learn_select.lesson.net_osi.title":    {"ru":"Модель OSI","kk":"OSI моделі","en":"OSI Model"},
"ui.learn_select.lesson.net_osi.subtitle": {"ru":"7 уровней, их функции","kk":"7 деңгей, олардың функциялары","en":"7 layers and their functions"},
"ui.learn_select.lesson.net_ip.title":     {"ru":"IP-адресация","kk":"IP-адрестеу","en":"IP Addressing"},
"ui.learn_select.lesson.net_ip.subtitle":  {"ru":"IPv4, классы адресов","kk":"IPv4, адрестер кластары","en":"IPv4, address classes"},
"ui.learn_select.lesson.net_mask.title":   {"ru":"Маски подсетей","kk":"Ішкі желі маскалары","en":"Subnet Masks"},
"ui.learn_select.lesson.net_mask.subtitle":{"ru":"CIDR, вычисление диапазонов","kk":"CIDR, диапазондарды есептеу","en":"CIDR, calculating ranges"},
"ui.learn_select.lesson.net_diag.title":   {"ru":"Диагностика сети","kk":"Желіні диагностикалау","en":"Network Diagnostics"},
"ui.learn_select.lesson.net_diag.subtitle":{"ru":"Ошибки, топология, трассировка","kk":"Қателер, топология, трассировка","en":"Errors, topology, traceroute"},

"ui.learn_select.lesson.graph_basics.title":    {"ru":"Графы: основы","kk":"Графтар: негіздер","en":"Graphs: Basics"},
"ui.learn_select.lesson.graph_basics.subtitle": {"ru":"Узлы, рёбра, типы графов","kk":"Түйіндер, қырлар, граф түрлері","en":"Nodes, edges, graph types"},
"ui.learn_select.lesson.graph_dijkstra.title":  {"ru":"Алгоритм Дейкстры","kk":"Дейкстра алгоритмі","en":"Dijkstra's Algorithm"},
"ui.learn_select.lesson.graph_dijkstra.subtitle":{"ru":"Кратчайший путь, шаг за шагом","kk":"Ең қысқа жол, қадамдап","en":"Shortest path, step by step"},
"ui.learn_select.lesson.algo_sort.title":       {"ru":"Сортировка","kk":"Сұрыптау","en":"Sorting"},
"ui.learn_select.lesson.algo_sort.subtitle":    {"ru":"Пузырёк, выборка, быстрая","kk":"Көпіршік, іріктеу, жылдам","en":"Bubble, selection, quick sort"},
"ui.learn_select.lesson.algo_complexity.title": {"ru":"Сложность O(n)","kk":"O(n) күрделілігі","en":"Complexity O(n)"},
"ui.learn_select.lesson.algo_complexity.subtitle":{"ru":"Big-O, O(n²), O(log n)","kk":"Big-O, O(n²), O(log n)","en":"Big-O, O(n²), O(log n)"},

"ui.learn_select.lesson.encode_ascii.title":    {"ru":"ASCII и Unicode","kk":"ASCII және Unicode","en":"ASCII and Unicode"},
"ui.learn_select.lesson.encode_ascii.subtitle": {"ru":"Таблица кодов, символы","kk":"Кодтар кестесі, таңбалар","en":"Code table, characters"},
"ui.learn_select.lesson.encode_freq.title":     {"ru":"Частотный анализ","kk":"Жиілік талдауы","en":"Frequency Analysis"},
"ui.learn_select.lesson.encode_freq.subtitle":  {"ru":"Дешифровка через частоты букв","kk":"Әріп жиіліктері арқылы шифрды ашу","en":"Decoding via letter frequencies"},
"ui.learn_select.lesson.matrix_cipher.title":   {"ru":"Матричные шифры","kk":"Матрицалық шифрлар","en":"Matrix Ciphers"},
"ui.learn_select.lesson.matrix_cipher.subtitle":{"ru":"Матрица ключей, перестановки","kk":"Кілттер матрицасы, орын ауыстыру","en":"Key matrix, permutations"},
"ui.learn_select.lesson.file_systems.title":    {"ru":"Файловые системы","kk":"Файлдық жүйелер","en":"File Systems"},
"ui.learn_select.lesson.file_systems.subtitle": {"ru":"FAT, NTFS, дерево каталогов","kk":"FAT, NTFS, каталогтар ағашы","en":"FAT, NTFS, directory tree"},
"ui.learn_select.lesson.sql_basics.title":      {"ru":"Базы данных: SQL","kk":"Деректер қоры: SQL","en":"Databases: SQL"},
"ui.learn_select.lesson.sql_basics.subtitle":   {"ru":"SELECT, WHERE, ORDER BY","kk":"SELECT, WHERE, ORDER BY","en":"SELECT, WHERE, ORDER BY"},

"ui.learn_select.progress":     {"ru":"{done} / {total} завершено","kk":"{done} / {total} аяқталды","en":"{done} / {total} completed"},

# ─── MISC FIXES ─────────────────────────────────────────────────────────────
"logic.a.ui.safe_brief": {"ru":"Диагностический отчёт.","kk":"Диагностикалық есеп.","en":"Diagnostic report."},
}

def load_json(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)

def save_json(path, data):
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved {path} ({len(data)} keys)")

ru = load_json(os.path.join(BASE, 'ru.json'))
kk = load_json(os.path.join(BASE, 'kk.json'))
en = load_json(os.path.join(BASE, 'en.json'))

added_ru = added_kk = added_en = 0
for key, translations in NEW_KEYS.items():
    if key not in ru:
        ru[key] = translations['ru']; added_ru += 1
    if key not in kk:
        kk[key] = translations['kk']; added_kk += 1
    if key not in en:
        en[key] = translations['en']; added_en += 1

# Fix existing en key that was left in Russian
en['logic.a.ui.safe_brief'] = 'Diagnostic report.'

save_json(os.path.join(BASE, 'ru.json'), ru)
save_json(os.path.join(BASE, 'kk.json'), kk)
save_json(os.path.join(BASE, 'en.json'), en)
print(f"\nAdded: ru={added_ru}, kk={added_kk}, en={added_en}")
