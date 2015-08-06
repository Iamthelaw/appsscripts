# Выбрать переменную из списка
hoho = (array) ->
  rand = Math.floor(Math.random() * array.length)
  array[rand]

# Основная функция
meta = (url) ->
  
  # Переменные
  time = new Date
  month = time.getMonth() + 1
  year = time.getFullYear()
  
  # Парсим страницу
  response = UrlFetchApp.fetch(url)
  html = response.getContentText()

  zk = /title=".*?">.*?</.exec(html) # ЖК
  id = /\d{6}/.exec(url) # id
  h1 = /2">.*?<\/h1>/.exec(html) # H1
  metadon = html.match(/content=".*?"/g) # Мета
  
  # Таблица с характеристиками
  table = html.match(/<td>.*?<\/td>/g)
  
  # Раскидываем значения по переменным
  for item, i in table
    item = table[i]
    if item == '<td>Комнат:</td>'
      apt = table[i + 1]
    else if item == '<td>Этаж:</td>'
      floor = table[i + 1]
    else if item == '<td>Площадь общая:</td>'
      ploshad = table[i + 1]
    else if item == '<td>Площадь жилая:</td>'
      ploshad_zh = table[i + 1]
    else if item == '<td>Район:</td>'
      raion = table[i + 1]
    else if item == '<td>Тип дома:</td>'
      dom = table[i + 1]
    else if item == '<td>Адрес дома:</td>'
      address = table[i + 1]
    else if item == '<td>Плановый срок сдачи:</td>'
      srok_plan = table[i + 1]
    else if item == '<td>Фактический срок сдачи:</td>'
      srok_fuckt = table[i + 1]
    else if item == '<td>Застройщик:</td>'
      zastroyshik = table[i + 1]
    else if item == '<td>Цена за кв метр:</td>'
      price_m = table[i + 1]
    else if item == '<td>Стоимость квартиры:</td>'
      price_total = table[i + 1]
    else if item == '<td>Ближайшее метро:</td>'
      metro = table[i + 1]

  # Небольшая чистка
  apt = apt.replace(/^<td>/, '').replace(/<\/td>$/, '')
  h1 = h1[0].replace(/^2">/, '').replace(/<\/h1>/, '')
  dom = dom.replace(/^<td>/, '').replace(/<\/td>$/, '')
  keywords = metadon[3].replace(/content="/, '').replace(/"$/, '')
  description = metadon[4].replace(/content="/, '').replace(/"$/, '')
  ploshad = ploshad.replace(/^<td>/, '').replace(/<\/td>$/, '')
  price_m = price_m.replace(/^<td>/, '').replace(/<\/td>$/, '').replace(/&nbsp;/, '').replace(/&nbsp;/, ' ').replace(/<sup>2<\/sup>/, '2')
  price_total = price_total.replace(/^<td>/, '').replace(/<\/td>$/, '').replace(/<span class=".*?">/, '').replace(/&nbsp;/g, ' ').replace(/<\/span>/, '.')
  price_int = price_total.replace(/\sруб./, '').replace(/\s/g, '')
  price_int = parseInt(price_int)
  if ploshad_zh != undefined
    ploshad_zh = ploshad_zh.replace(/^<td>/, '').replace(/<\/td>$/, '')
  metro_link = /\/\w*?\/\w*?\//.exec(metro)
  if metro != undefined
    metro = metro.replace(/<td><a href="\/.*?\/.*?\/">/, '').replace(/<\/a><\/td>/, '')

  ###
  # Данные для первого предложения
  ###

  rain = raion
  rain = /\/\w*?\/\w*?\//.exec(rain)

  # Вычленяем тип квартиры (1 ком, студия) из описания
  if /^\d/.test(description)
    type = /^.*?\s.*?\s/.exec(description)
  else
    type = /^.*?\s/.exec(description)
  type = type[0].trim()

  # Парсим название жк. Если в строке есть адрес парсим его тоже
  if /\sул\.\s/.test(zk)
    address = zk[0].replace(/title=".*?">/, '').replace(/</, '').replace(/ЖК\sв\s/, '').replace(/\s\—.*$/, '')
    zk = zk[0].replace(/title=".*?">/, '').replace(/</, '').replace(/,.*$/, '')
  else
    zk = zk[0].replace(/title=".*?">/, '').replace(/</, '')

  # Застройщик
  zastroyshik = zastroyshik.replace(/^<td>/, '').replace(/<\/td>$/, '').replace(/^<a\shref=".*?">/, '').replace(/<\/a>$/, '')
  
  # Составляем первое предложение в описании
  full_desc = [['В ', zk, ' от строительной компании ', zastroyshik, ' продается ', type, '.'].join('') ]
  
  ###
  # Адрес и Район
  ###

  raion = raion.replace(/<td>/, '').replace(/<\/td>/, '').replace(/<.\shref=".*?">/, '').replace(/<\/a>/, '')
  
  # Борьба с в и во
  if raion == 'Всеволожский'
    raion_v = ' во ' + raion.replace(/ий$/, 'ом')
  else
    raion_v = ' в ' + raion.replace(/ий$/, 'ом')

  # Если адрес не указан
  if address != undefined
    address = address.replace(/^<td>/, '').replace(/<\/td>$/, '')
    full_desc.push ['Новостройка расположена по адресу: ', raion, ' район, ', address, '.'].join('')
  else
    full_desc.push ['Новостройка расположена', raion_v, ' районе.'].join('')
  
  ###
  # Тип квартиры
  ###

  # Добавление текста про тип квартиры
  if type == 'Квартира-студия'
    type_v = 'Квартиры-студии'
    full_desc.push hoho([
      '\nКвартира-студия - идеальный вариант жилья для тех, кто желает начать самостоятельную жизнь.'
      '\nСтудия - лучший выбор для молодого человека или девушки, мечтающего съехать от родителей.'
      '\nОптимальный выбор жилья для переезжающих в Петербург - квартира-студия.'
      '\nКвартира-студия подходит для тех, кому важно удобное расположение и низкая стоимость.'
    ])
  else
    type_v = type.replace(/ая/, 'ые').replace(/а$/, 'ы')

  # Добавить текст про этажность если есть характеристика
  if floor != undefined
    floor = floor.replace(/^<td>/, '').replace(/<\/td>$/, '')
    full_desc.push ['Квартира расположена на ', floor, '-м этаже.'].join('')
  
  # Общая площадь всегда есть, добавляем текст в описание
  full_desc.push ['Общая площадь квартиры составляет ', ploshad, ' м2.'].join('')
  
  ploshad_int = Math.floor(parseInt(ploshad)) # Приводим площадь к целому числу
  
  # Добавляем текст в зависимости от площади квартиры
  if ploshad_int < 25
    full_desc.push hoho([
      'Небольшая площадь квартиры используется по максимуму эффективно грамотной планировкой.'
      'Квартира маленькая по площади, но очень уютная.'
      'Квартира маленькой площади, но каждый квадратный сантиметр использован в планировке максимально эффективно.'
      'Площадь квартиры небольшая, но правильная планировка и отделка в светлых тонах визуально расширят пространство.'
    ])
  else if ploshad_int < 50
    full_desc.push hoho([
      'Площадь квартиры позволит уютно обставить жилье мебелью, и при этом останется свободное пространство.'
      'В квартире такой площади семья из 2-3 человек будет комфортно себя чувствовать.'
      'Оптимальная площадь позволит уютно себя чувствовать в квартире.'
      'Средняя площадь квартиры подходит для семьи, ценящей комфорт и уют.'
    ])
  else if ploshad_int <= 100
    full_desc.push hoho([
      'В квартире такой площади хватит места на всю семью, мебель и домашних питомцев.'
      'Просторная квартира с хорошей планировкой.'
      'Большая площадь квартиры позволит с комфортом разместиться всей семье.'
      'В такой просторной квартире дети и взрослые смогут иметь свое личное пространство.'
    ])
  else if ploshad_int > 100
    full_desc.push hoho([
      'В квартире такой площади хватит места на воплощение в жизнь любых задумок.'
      'Очень большая площадь квартиры позволит распланировать все по Вашему вкусу.'
      'В квартире такой площади каждой комнате можно назначить особую функциональность.'
      'Собственный кабинет, гостиная, спальня, детская - в квартиру огромной площади войдет все.'
    ])

  ###
  # Класс дома
  ###
  
  # Определяем класс дома
  if dom == 'Кирпичный'
    dom_class = 'комфорт'
  else if dom == 'Монолитный'
    dom_class = 'эконом'
  else
    dom_class = 'эконом'
  
  # Добавляем предложение о классе дома
  full_desc.push ['\nДом строится по технологии ', dom.toLowerCase(), ' и относится к ', dom_class, ' классу жилья.'].join('')
  
  # Если есть фактический срок сдачи он становится основным
  if srok_fuckt == undefined
    srok = srok_plan.replace(/^<td>/, '').replace(/<\/td>$/, '')
  else
    srok = srok_fuckt.replace(/^<td>/, '').replace(/<\/td>$/, '')

  # Год сдачи в целое число
  srok_int = /\d{4}/.exec(srok)
  srok_int = parseInt(srok_int[0])

  # Определяем текущий квартал
  if month <= 12
    sdan = 4
  else if month <= 9
    sdan = 3
  else if month >= 6
    sdan = 2
  else if month >= 3
    sdan = 1

  # Конвертируем квартал в характеристике в число
  if /^I\s/.test(srok)
    sdan2 = 1
  else if /^II\s/.test(srok)
    sdan2 = 2
  else if /^III\s/.test(srok)
    sdan2 = 3
  else if /^IV\s/.test(srok)
    sdan2 = 4

  # Определяем сдан ли дом в эксплуатацию и добавляем нужный текст
  if srok_int == year
    if sdan2 >= sdan
      full_desc.push [
        'Планируемая дата сдачи дома в эксплуатацию - ', srok, '.'].join('')
    else
      full_desc.push 'Дом сдан в эксплуатацию.'
  else if srok_int <= year
    full_desc.push 'Дом сдан в эксплуатацию.'
  else if srok_int >= year
    full_desc.push ['Планируемая дата сдачи дома в эксплуатацию - ', srok, '.'].join('')
  
  ###
  # Цены
  ###
  
  # Конечный текст
  full_desc.push ['Стоимость квадратного метра в ', zk, ' составляет ', price_m, '.'].join('')
  full_desc.push ['Общая стоимость квартиры 2 773 890 рублей.'].join('')
  full_desc.push '\nЕсли Вас заинтересовала данная квартира, Вы можете оставить запрос на приобретение, а также уточнить любую интересующую вас информацию. Для получения информации о наличие квартир и стоимости необходимо заполнить форму заявки, или позвонить по контактному телефону.\nКвартиру можно приобрести по программе материнского капитала, военной ипотеке, в рассрочку. Принимаются субсидии. Ипотечный кредит на первичном рынке можно получить в банках, которые аккредитовали данный объект, а также в других банках предоставляющих кредиты на покупку жилья на первичном рынке.'
  
  # Определяем ценовой диапазон
  if price_int >= 4500000
    link_price = ' до 5 млн руб.'
  else if price_int >= 4000000
    link_price = ' до 4,5 млн руб.'
  else if price_int >= 3500000
    link_price = ' до 4 млн руб.'
  else if price_int >= 3000000
    link_price = ' до 3,5 млн руб.'
  else if price_int >= 2500000
    link_price = ' до 3 млн руб.'
  else if price_int >= 2000000
    link_price = ' до 2,5 млн руб.'
  else if price_int >= 1500000
    link_price = ' до 2 млн руб.'
  else if price_int >= 1000000
    link_price = ' до 1,5 млн руб.'
  else if price_int >= 500000
    link_price = ' до 1 млн руб.'

  # Составляем description, keywords, h1  
  description = [type, 'площадью', ploshad + ' м2', 'в', zk, raion, 'район. Цена за кв м.:', price_m, ',', price_total, ' - за квартиру. Подробное описание и планировка на портале Nevastroyka.'].join(' ')
  keywords = [type, zk, 'площадь ' + ploshad + ' м2', 'цена ' + price_total, raion.toLowerCase() + ' район', dom.toLowerCase() + ' дом', 'около метро ' + metro, ' планировка, отзывы, фотографии, обсуждение, ход строительства, Nevastroyka'].join(', ')
  h1 = [type, ploshad + ' м2', 'в', zk, '-', price_total].join(' ')
  # Ссылка для района
  rain = [type_v, raion_v, ' районе', link_price, ' от застройщика [', 'http://nevastroyka.ru', rain, ']'].join('')
  # Ссылка для метро (если метро указано)
  if metro != undefined
    metro_li = [type_v, ' около метро "', metro, '"', link_price, ' от застройщика [', 'http://nevastroyka.ru', metro_link, ']'].join('')
  
  # Возвращаем все это дело в виде таблицы
  [[id[0], h1, keywords, description, rain, metro_li, full_desc.join(' ')]]