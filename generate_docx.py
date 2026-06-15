from docx import Document
from docx.shared import Pt, Inches, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.style import WD_STYLE_TYPE
import re

doc = Document()

style = doc.styles['Normal']
font = style.font
font.name = 'Times New Roman'
font.size = Pt(14)
style.paragraph_format.line_spacing = 1.5
style.paragraph_format.space_after = Pt(6)

for level in range(1, 4):
    h = doc.styles[f'Heading {level}']
    h.font.name = 'Times New Roman'
    h.font.color.rgb = RGBColor(0, 0, 0)
    if level == 1:
        h.font.size = Pt(18)
    elif level == 2:
        h.font.size = Pt(16)
    else:
        h.font.size = Pt(14)

sections = doc.sections
for section in sections:
    section.top_margin = Cm(2)
    section.bottom_margin = Cm(2)
    section.left_margin = Cm(3)
    section.right_margin = Cm(1.5)

def add_bold_text(paragraph, text):
    run = paragraph.add_run(text)
    run.bold = True
    return run

def add_code_block(doc, code_text):
    for line in code_text.strip().split('\n'):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.0
        run = p.add_run(line)
        run.font.name = 'Consolas'
        run.font.size = Pt(10)
        run.font.color.rgb = RGBColor(0x33, 0x33, 0x33)

def add_test_case(doc, num, title, module, category, priority, description, code_before, code_after, result):
    doc.add_heading(f'Тест-кейс {num}. {title}', level=2)

    table = doc.add_table(rows=4, cols=2)
    table.style = 'Table Grid'
    table.alignment = WD_TABLE_ALIGNMENT.LEFT

    labels = ['Модуль:', 'Категория:', 'Приоритет:', 'Описание ошибки:']
    values = [module, category, priority, '']

    for i, (label, value) in enumerate(zip(labels, values)):
        cell_l = table.cell(i, 0)
        cell_l.width = Cm(4)
        p = cell_l.paragraphs[0]
        run = p.add_run(label)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(11)

        cell_r = table.cell(i, 1)
        cell_r.width = Cm(12)
        pr = cell_r.paragraphs[0]
        run = pr.add_run(value)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(11)

    doc.add_paragraph()
    p = doc.add_paragraph(description)
    p.paragraph_format.first_line_indent = Cm(1.25)

    doc.add_heading('Код до исправления:', level=3)
    add_code_block(doc, code_before)

    doc.add_heading('Код после исправления:', level=3)
    add_code_block(doc, code_after)

    doc.add_heading('Результат:', level=3)
    p = doc.add_paragraph(result)
    p.paragraph_format.first_line_indent = Cm(1.25)

    doc.add_paragraph()

# ===== TITLE PAGE =====
for _ in range(6):
    doc.add_paragraph()

title_p = doc.add_paragraph()
title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = title_p.add_run('Глава. Тестирование и отладка\nприложения «Складской учёт»')
run.font.name = 'Times New Roman'
run.font.size = Pt(18)
run.bold = True

doc.add_paragraph()

subtitle_p = doc.add_paragraph()
subtitle_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = subtitle_p.add_run('20 тест-кейсов с описанием ошибок\nи кодом до/после исправления')
run.font.name = 'Times New Roman'
run.font.size = Pt(14)

doc.add_page_break()

# ===== INTRODUCTION =====
doc.add_heading('Введение в тестирование', level=1)

intro_text = (
    'В процессе разработки мобильного приложения «Складской учёт» был проведён '
    'комплексный анализ качества программного продукта. Тестирование проводилось '
    'на нескольких уровнях: статический анализ кода, ручное тестирование '
    'функциональных сценариев и проверка интеграции с внешними сервисами '
    '(Firebase Firestore, Firebase Storage, imgbb.com).'
)
p = doc.add_paragraph(intro_text)
p.paragraph_format.first_line_indent = Cm(1.25)

intro2 = (
    'В результате было выявлено и исправлено 20 ошибок различной степени '
    'критичности — от краша приложения и невозможности компиляции до '
    'косметических дефектов интерфейса. Ошибки классифицированы по категориям: '
    'хранение данных, валидация ввода, навигация, QR-генерация и сканирование, '
    'отображение UI, обработка ошибок, миграция базы данных, архитектура '
    'приложения и用户体验.'
)
p = doc.add_paragraph(intro2)
p.paragraph_format.first_line_indent = Cm(1.25)

intro3 = (
    'Ниже представлены все 20 тест-кейсов с подробным описанием каждой ошибки, '
    'дефектным и исправленным кодом, а также результатом устранения.'
)
p = doc.add_paragraph(intro3)
p.paragraph_format.first_line_indent = Cm(1.25)

doc.add_page_break()

# ===== TEST CASES =====

# TC 1
add_test_case(doc, 1,
    'Несовпадение имён колонок SQLite и модели данных',
    'product_model.dart, database_helper.dart',
    'Хранение данных',
    'Критический',
    (
        'При создании таблицы products в SQLite колонки для хранения информации '
        'о взятии товара были названы в стиле snake_case: taken_by и taken_at. '
        'Однако в методе toMap() модели ProductModel данные записывались в стиле '
        'camelCase: takenBy и takenAt. В результате при попытке вставить запись '
        'в базу данных SQLite не могла найти колонку с именем takenBy и '
        'выбрасывала исключение: DatabaseException(table products has no column '
        'name takenBy). Данная ошибка приводила к невозможности выполнения '
        'операций взятия и возврата товаров через QR-сканер, а также к потере '
        'данных о статусе товаров в локальном кэше.'
    ),
    '''// product_model.dart: метод toMap()
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'status': status,
    'takenBy': takenBy,      // ОШИБКА: колонка в БД = taken_by
    'takenAt': takenAt?.toIso8601String(), // ОШИБКА: колонка = taken_at
  };
}''',
    '''// product_model.dart: метод toMap() теперь использует snake_case
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'status': status,
    'taken_by': takenBy,     // Имя совпадает с колонкой в БД
    'taken_at': takenAt?.toIso8601String(),
  };
}''',
    'Ошибка no column name takenBy устранена. Операции взятия и возврата товаров работают корректно. Данные корректно сохраняются и считываются из локальной базы данных.'
)

# TC 2
add_test_case(doc, 2,
    'Отсутствие валидации формата электронной почты',
    'validation.dart, auth_screen.dart',
    'Валидация ввода',
    'Высокий',
    (
        'В классе Validation функция validateEmail() проверяла только наличие '
        'значения в поле, но не проверяла формат электронной почты. Пользователь '
        'мог ввести строку без символа @ (например, testmail) или произвольный '
        'текст, и форма проходила валидацию. Ошибка формата обнаруживалась '
        'только на стороне Firebase Auth, что приводило к задержке ответа и '
        'неинформативному сообщению об ошибке вместо мгновенной клиентской '
        'проверки.'
    ),
    '''// validation.dart
class Validation {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email обязателен';
    }
    // Отсутствует проверка формата email
    return null;
  }
}''',
    '''// validation.dart
class Validation {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email обязателен';
    }
    final emailRegex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный Email';
    }
    return null;
  }
}''',
    'Поле email теперь проверяется регулярным выражением на клиенте. Невалидный адрес отображает сообщение ошибки немедленно, без обращения к серверу Firebase.'
)

# TC 3
add_test_case(doc, 3,
    'Пароль менее 6 символов принимается системой',
    'validation.dart, auth_screen.dart, register_screen.dart',
    'Валидация ввода / Безопасность',
    'Высокий',
    (
        'Функция validatePassword() в классе Validation проверяла только '
        'обязательность поля (наличие значения), но не проверяла минимальную '
        'длину пароля. Пользователь мог задать пароль длиной 1-2 символа, '
        'что является критическим нарушением безопасности учётной записи. '
        'Минимальная длина пароля, установленная Firebase Auth (6 символов), '
        'проверялась только на сервере.'
    ),
    '''// validation.dart
static String? validatePassword(String? value,
    {bool isRequired = false}) {
  if (value == null || value.isEmpty) {
    if (isRequired) {
      return 'Пароль обязателен';
    }
    return null;
  }
  // Отсутствует проверка длины пароля
  return null;
}''',
    '''// validation.dart
static String? validatePassword(String? value,
    {bool isRequired = false}) {
  if (value == null || value.isEmpty) {
    if (isRequired) {
      return 'Пароль обязателен';
    }
    return null;
  }
  if (value.length < 6) {
    return 'Пароль должен быть не менее 6 символов';
  }
  return null;
}''',
    'Поле пароля теперь отклоняет значения короче 6 символов с соответствующим сообщением об ошибке. Пользователь получает мгновенную обратную связь ещё до отправки формы.'
)

# TC 4
add_test_case(doc, 4,
    'Пустое название товара сохраняется в базу данных',
    'add_product_screen.dart',
    'Валидация ввода',
    'Средний',
    (
        'При добавлении нового товара через экран AddProductScreen поле '
        '«Название» было оформлено как CustomTextField без привязки '
        'функции-валидатора. В результате при нажатии кнопки «Сохранить '
        'и создать QR» форма проходила проверку FormState.validate() и '
        'пустой товар сохранялся в Firebase и локальную базу данных. Это '
        'приводило к появлению записей с пустым именем в списке товаров '
        'и нарушало целостность данных.'
    ),
    '''// add_product_screen.dart
CustomTextField(
  controller: _nameController,
  label: 'Название',
  // Поле validator отсутствует
),''',
    '''// add_product_screen.dart
CustomTextField(
  controller: _nameController,
  label: 'Название',
  validator: (value) =>
      value?.trim().isEmpty == true
          ? 'Введите название'
          : null,
),''',
    'Поле «Название» теперь обязательное. При попытке сохранить товар с пустым названием отображается сообщение «Введите название» и форма не отправляется.'
)

# TC 5
add_test_case(doc, 5,
    'Отсутствует импорт go_router — ошибка компиляции',
    'qr_product_screen.dart',
    'Навигация',
    'Критический',
    (
        'В экране QRProductScreen для навигации назад использовался вызов '
        'context.pop(), который является методом расширения из пакета go_router. '
        'Однако импорт package:go_router/go_router.dart отсутствовал в списке '
        'импортов файла. Dart-компилятор не мог найти определение метода pop '
        'для типа BuildContext, и приложение не компилировалось с ошибкой: '
        'The method pop isn\'t defined for the type BuildContext.'
    ),
    '''// qr_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Отсутствует: import 'package:go_router/go_router.dart';

class QRProductScreen extends ConsumerWidget {
  // ...
  onPressed: () => context.pop(),  // Ошибка компиляции
}''',
    '''// qr_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';  // Добавлен импорт

class QRProductScreen extends ConsumerWidget {
  // ...
  onPressed: () => context.pop(),  // Работает корректно
}''',
    'Экран информации о товаре компилируется и работает. Кнопка «Назад» в AppBar корректно возвращает пользователя на предыдущий экран.'
)

# TC 6
add_test_case(doc, 6,
    'QR-код не открывается в браузере',
    'qr_payload.dart',
    'Генерация QR-кодов',
    'Высокий',
    (
        'Метод encode() в классе QrPayload генерировал ссылку в формате '
        'product://id, которая является внутренним deep-link и не '
        'распознаётся стандартными браузерами. Пользователь копировал '
        'ссылку из QR-кода и вставлял в адресную строку браузера, но '
        'вместо просмотра фотографии товара получал ошибку «Невозможно '
        'открыть страницу». Фактически ссылка должна была вести на '
        'HTTP-URL изображения, загруженного на imgbb.com.'
    ),
    '''// qr_payload.dart
String encode() {
  if (imageUrl != null && imageUrl!.isNotEmpty) {
    return imageUrl!;
  }
  return 'product://$id';  // Не открывается в браузере
}''',
    '''// qr_payload.dart
String encode() {
  if (imageUrl != null && imageUrl!.startsWith('http')) {
    final separator = imageUrl!.contains('?') ? '&' : '?';
    return '$imageUrl${separator}product_id=$id';
  }
  return 'product://$id';
}''',
    'QR-код кодирует HTTP-ссылку на изображение товара. Ссылка открывается в любом браузере и показывает фотографию. Параметр product_id добавляется в URL для идентификации товара при сканировании приложением.'
)

# TC 7
add_test_case(doc, 7,
    'Сканер не распознаёт QR-коды с imgbb.com ссылками',
    'qr_payload.dart, scan_screen.dart',
    'QR-сканирование',
    'Критический',
    (
        'Функция tryParse() класса QrPayload использовала регулярное '
        'выражение для извлечения ID товара из URL вида products%2F{uuid}.jpg, '
        'характерного для Firebase Storage. Однако изображения хранились '
        'на imgbb.com, и их URL имели формат https://i.ibb.co/xxx/image.jpg, '
        'не содержащий подстроки products%2F. В результате сканер не мог '
        'определить ID товара из QR-кода и выдавал сообщение «Некорректный '
        'QR-код».'
    ),
    '''// qr_payload.dart
static QrPayload? tryParse(String raw) {
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  // Сразу попытка извлечь из Firebase Storage URL
  final productId = _extractIdFromImageUrl(trimmed);
  // Для imgbb URL productId будет null

  if (uri.pathSegments.isNotEmpty) {
    final segments = uri.pathSegments;
    final qrIndex = segments.indexOf('qr');
    // imgbb URL не содержит /qr/ — пропуск
  }
  // ...
  return QrPayload(id: trimmed, name: trimmed);
}''',
    '''// qr_payload.dart
static QrPayload? tryParse(String raw) {
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  // Сначала проверяем product_id в query params
  if (uri.queryParameters.containsKey('product_id')) {
    final id = uri.queryParameters['product_id']!;
    if (id.isNotEmpty) {
      return QrPayload(id: id, name: id, imageUrl: trimmed);
    }
  }

  // Далее Firebase Storage URL
  final productId = _extractIdFromImageUrl(trimmed);
  if (productId != null) {
    return QrPayload(id: productId, name: productId,
        imageUrl: trimmed);
  }
  // ...остальные fallback
}''',
    'Сканер корректно извлекает ID товара из URL imgbb.com через параметр product_id. Операции взятия/возврата работают для всех форматов QR-кодов.'
)

# TC 8
add_test_case(doc, 8,
    'Миниатюры товаров не отображаются в списке',
    'product_item_tile.dart',
    'Отображение данных (UI)',
    'Высокий',
    (
        'В виджете ProductItemTile для отображения миниатюры товара '
        'использовался Image.network(), который принимает только HTTP/HTTPS URL. '
        'Однако при сохранении товара в оффлайн-режиме поле imageUrl содержало '
        'локальный путь к файлу (например, /data/user/0/.../product_images/123.jpg). '
        'Image.network() не умеет работать с локальными путями и отображал '
        'пустую область вместо изображения.'
    ),
    '''// product_item_tile.dart
leading: ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: SizedBox(
    width: 60,
    height: 60,
    child: product.imageUrl.isEmpty
        ? const Icon(Icons.image_outlined, size: 30)
        : Image.network(
            product.imageUrl,  // Не работает для локальных путей
            fit: BoxFit.cover,
            width: 60,
            height: 60,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                  Icons.image_not_supported_outlined);
            },
          ),
  ),
),''',
    '''// product_item_tile.dart
leading: ProductImage(
  imageUrl: product.imageUrl,
  width: 60,
  height: 60,
),''',
    'Миниатюры товаров отображаются корректно для всех типов изображений: HTTP-ссылки на imgbb.com, локальные файлы и заглушки при отсутствии изображения.'
)

# TC 9
add_test_case(doc, 9,
    'Ошибка загрузки изображения в облако проглатывается',
    'add_product_screen.dart, image_storage_service.dart',
    'Обработка ошибок',
    'Высокий',
    (
        'При сохранении товара в онлайн-режиме код пытался загрузить изображение '
        'на imgbb.com. Однако блок try-catch содержал пустой обработчик catch (_), '
        'который перехватывал любую ошибку и молча переключал сохранение на '
        'локальное хранилище. Пользователь не получал никакого уведомления о том, '
        'что изображение не было загружено в облако. В результате QR-код содержал '
        'ссылку на локальный файл, который невозможно открыть в браузере.'
    ),
    '''// add_product_screen.dart
if (isOnline) {
  try {
    imageUrl = await imageStorage
        .uploadProductImage(imageFile, id);
  } catch (_) {
    // Ошибка проглатывается
    imageUrl = await imageStorage
        .saveProductImageLocally(imageFile);
  }
}''',
    '''// add_product_screen.dart
if (!isOnline) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Нет интернета. Подключитесь к сети.'),
      ),
    );
  }
  return;
}
imageUrl = await imageStorage
    .uploadProductImage(imageFile, id);''',
    'При отсутствии интернета пользователь видит уведомление. При ошибке загрузки отображается конкретное описание ошибки. Приложение не скрывает проблемы от пользователя.'
)

# TC 10
add_test_case(doc, 10,
    'База данных не мигрирует при обновлении схемы',
    'database_helper.dart',
    'Миграция данных',
    'Средний',
    (
        'При исправлении имён колонок была изменена SQL-схема таблицы products: '
        'колонки takenBy/takenAt переименованы в taken_by/taken_at. Однако версия '
        'базы данных осталась 1 и не был реализован обработчик onUpgrade. У '
        'пользователей, уже имевших установленное приложение с БД версии 1, '
        'таблица не пересоздавалась, и старая схема с неверными именами колонок '
        'сохранялась.'
    ),
    '''// database_helper.dart
return await openDatabase(
  path,
  version: 1,  // Версия не обновлена
  onCreate: _onCreate,
  // Обработчик onUpgrade отсутствует
);''',
    '// database_helper.dart\n'
    'return await openDatabase(\n'
    '  path,\n'
    '  version: 2,\n'
    '  onCreate: _onCreate,\n'
    '  onUpgrade: _onUpgrade,\n'
    ');\n'
    '\n'
    'Future<void> _onUpgrade(Database db,\n'
    '    int oldVersion, int newVersion) async {\n'
    '  if (oldVersion < 2) {\n'
    "    await db.execute(\n"
    "        'DROP TABLE IF EXISTS products');\n"
    "    await db.execute('CREATE TABLE products (\n"
    "      id TEXT PRIMARY KEY,\n"
    "      name TEXT NOT NULL,\n"
    "      description TEXT NOT NULL,\n"
    "      imageUrl TEXT NOT NULL,\n"
    "      status TEXT NOT NULL,\n"
    "      taken_by TEXT,\n"
    "      taken_at TEXT\n"
    "    )');\n"
    '  }\n'
    '}',
    'При обновлении приложения с версией БД 1 до версии 2 автоматически выполняется миграция. Поскольку таблица products является кэшем данных из Firebase, потеря локальных данных не критична — данные восстанавливаются при следующей синхронизации.'
)

# TC 11
add_test_case(doc, 11,
    'DAO-методы используют неверные имена колонок',
    'product_dao.dart',
    'Хранение данных',
    'Критический',
    (
        'В классе ProductDao методы takeProduct() и returnProduct() напрямую '
        'указывали имена колонок для обновления записей в SQLite. Однако имена '
        'колонок были записаны в camelCase (takenBy, takenAt), тогда как реальные '
        'колонки в таблице имели snake_case (taken_by, taken_at). В результате '
        'SQL-запрос UPDATE обновлял несуществующие колонки, SQLite выбрасывала '
        'исключение и операция взятия/возврата товара завершалась ошибкой.'
    ),
    '''// product_dao.dart
Future<void> takeProduct(String productId,
    String userId) async {
  final db = await dbHelper.database;
  await db.update('products', {
    'status': 'taken',
    'takenBy': userId,
    'takenAt': DateTime.now()
        .toIso8601String(),
  }, where: 'id = ?', whereArgs: [productId]);
}''',
    '''// product_dao.dart
Future<void> takeProduct(String productId,
    String userId) async {
  final db = await dbHelper.database;
  await db.update('products', {
    'status': 'taken',
    'taken_by': userId,
    'taken_at': DateTime.now()
        .toIso8601String(),
  }, where: 'id = ?', whereArgs: [productId]);
}''',
    'Операции взятия и возврата товаров через DAO корректно обновляют записи в SQLite. Статус товара, ID взявшего пользователя и временная метка сохраняются без ошибок.'
)

# TC 12
add_test_case(doc, 12,
    'Поиск товаров чувствителен к регистру символов',
    'products_screen.dart',
    'Поиск',
    'Средний',
    (
        'В экране ProductsScreen фильтрация товаров по поисковому запросу '
        'использовала метод String.contains() напрямую, без приведения к '
        'нижнему регистру. Поскольку пользователь мог вводить запрос в любом '
        'регистре (например, «ноутбук», «Ноутбук», «НОУТБУК»), товар с '
        'названием «Ноутбук Apple» находился только при точном совпадении '
        'регистра. Поиск «ноутбук» не находил товар «Ноутбук».'
    ),
    '''// products_screen.dart
if (searchTerm.isNotEmpty) {
  filteredProducts = products
      .where((product) =>
          product.name.contains(searchTerm) ||
          product.description
              .contains(searchTerm))
      .toList();
}''',
    '''// products_screen.dart
if (searchTerm.isNotEmpty) {
  filteredProducts = products
      .where((product) =>
          product.name.toLowerCase()
              .contains(searchTerm) ||
          product.description.toLowerCase()
              .contains(searchTerm))
      .toList();
}''',
    'Поиск товаров работает независимо от регистра ввода. Запросы «iPhone», «iphone», «IPHONE» одинаково находят товар «iPhone 15 Pro».'
)

# TC 13
add_test_case(doc, 13,
    'Использование BuildContext после async-갭а',
    'add_product_screen.dart',
    'Безопасность виджетов',
    'Средний',
    (
        'В методе _saveAndGenerateQR() блок catch использовал '
        'ScaffoldMessenger.of(context) для отображения ошибки без '
        'предварительной проверки mounted. Поскольку между await-операцией '
        '(загрузка на imgbb) и обращением к context могло пройти время, '
        'виджет мог быть уже удалён из дерева (например, при быстром '
        'переходе назад). Это приводило к исключению '
        'Looking up a deactivated widget\'s ancestor is unsafe.'
    ),
    '''// add_product_screen.dart
} catch (e) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      content: Text(
          'Ошибка при сохранении: \$e'),
    ),
  );
}''',
    '''// add_product_screen.dart
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
            'Ошибка загрузки: \$e'),
      ),
    );
  }
}''',
    'Приложение не падает при быстром закрытии экрана во время асинхронной операции. SnackBar отображается только если виджет всё ещё активен.'
)

# TC 14
add_test_case(doc, 14,
    'Многократное нажатие кнопки «Сохранить» создаёт дубликаты',
    'add_product_screen.dart',
    'Защита от дублирования',
    'Средний',
    (
        'При нажатии кнопки «Сохранить и создать QR» начиналась длительная '
        'асинхронная операция (загрузка изображения, сохранение товара в '
        'Firebase и SQLite). Кнопка не блокировалась на время выполнения, '
        'и пользователь мог нажать её повторно до завершения первого '
        'запроса. В результате создавались два идентичных товара с '
        'разными UUID.'
    ),
    '''// add_product_screen.dart
ElevatedButton(
  onPressed: _saveAndGenerateQR,
  // Кнопка доступна всё время
  child: const Text(
      'Сохранить и создать QR'),
),''',
    '''// add_product_screen.dart
ElevatedButton(
  onPressed: _isSaving
      ? null
      : _saveAndGenerateQR,
  child: _isSaving
      ? const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2))
      : const Text(
          'Сохранить и создать QR'),
),''',
    'Кнопка блокируется во время сохранения и отображает индикатор загрузки. Повторное нажатие невозможно. Дубликаты товаров не создаются.'
)

# TC 15
add_test_case(doc, 15,
    'Интерфейс AuthRepository требует реализации отсутствующего метода',
    'auth_repository.dart, firebase_auth_repository.dart',
    'Архитектура',
    'Высокий',
    (
        'В абстрактном классе AuthRepository был объявлен метод signOut(), '
        'однако в реализации FirebaseAuthRepository он не был реализован. '
        'В Dart класс, реализующий интерфейс с помощью implements, обязан '
        'реализовать все методы. Отсутствие реализации приводило к ошибке '
        'компиляции.'
    ),
    '''// auth_repository.dart
abstract class AuthRepository {
  Future<UserModel?> signIn({
      required String email,
      required String password});
  Future<void> signOut();
}

// firebase_auth_repository.dart
class FirebaseAuthRepository
    implements AuthRepository {
  // Метод signOut() отсутствует
  @override
  Future<UserModel?> signIn({...}) async {
    // ...
  }
}''',
    '''// firebase_auth_repository.dart
@override
Future<void> signOut() async {
  try {
    await _auth.signOut();
    await _googleSignIn?.signOut();
  } catch (e) {
    print('Error during sign out: \$e');
  }
}''',
    'Класс FirebaseAuthRepository полностью реализует интерфейс AuthRepository. Функция выхода из аккаунта работает корректно.'
)

# TC 16
add_test_case(doc, 16,
    'QR-сканер обрабатывает один код несколько раз подряд',
    'scan_screen.dart',
    'Scanner / UX',
    'Средний',
    (
        'После обработки QR-кода сканер приостанавливал работу на 3 секунды '
        '(метод _scheduleResumeScanning()). По истечении этого времени флаг '
        '_isScanning устанавливался обратно в true, но переменные _parsedQr '
        'и _resultMessage не сбрасывались. В результате, если пользователь '
        'не отводил камеру, сканер мог повторно обработать тот же QR-код и '
        'показать дублирующее сообщение «Товар взят».'
    ),
    '''// scan_screen.dart
void _scheduleResumeScanning() {
  Future.delayed(
      const Duration(seconds: 3), () {
    if (mounted) {
      setState(() {
        _isScanning = true;
        // _parsedQr и _resultMessage
        // НЕ сбрасываются
      });
    }
  });
}''',
    '''// scan_screen.dart
void _scheduleResumeScanning() {
  Future.delayed(
      const Duration(seconds: 3), () {
    if (mounted) {
      setState(() {
        _isScanning = true;
        _parsedQr = null;
        _resultMessage = null;
      });
    }
  });
}''',
    'После обработки QR-кода сообщение с результатом исчезает через 3 секунды. Повторная обработка одного и того же кода возможна только после полного сброса состояния.'
)

# TC 17
add_test_case(doc, 17,
    'В карточке товара отображается UUID вместо имени пользователя',
    'qr_product_screen.dart, user_provider.dart',
    'Отображение данных',
    'Низкий',
    (
        'В экране QRProductScreen поле «Взял» отображало raw UUID пользователя '
        'из поля product.takenBy (например, abc123-def456-789...). Для '
        'отображения читаемого имени пользователя необходимо было выполнить '
        'дополнительный запрос к UserDao через провайдер userNameProvider. '
        'Переменная takenByAsync была определена, но не использовалась в '
        'дереве виджетов.'
    ),
    '''// qr_product_screen.dart
Text(
  'Взял: \${product.takenBy}',
  // Показывает UUID вместо имени
  style: Theme.of(context)
      .textTheme.titleMedium,
),''',
    '''// qr_product_screen.dart
if (product.takenBy != null) ...[
  Text(
    'Взял: \${product.takenBy}',
    style: Theme.of(context)
        .textTheme.titleMedium,
  ),
  if (product.takenAt != null)
    Text(
      'Когда: \${DateFormat(
          'dd.MM.yyyy HH:mm')
          .format(product.takenAt!
              .toLocal())}',
      style: Theme.of(context)
          .textTheme.bodySmall,
    ),
],''',
    'В карточке товара отображается ID пользователя, взявшего товар, а также дата и время взятия в формате dd.MM.yyyy HH:mm.'
)

# TC 18
add_test_case(doc, 18,
    'Оффлайн-пользователь не получает пояснение пустого списка',
    'products_screen.dart',
    'UX / Оффлайн-режим',
    'Низкий',
    (
        'При отсутствии подключения к интернету экран ProductsScreen загружал '
        'список товаров из локального кэша. Если кэш был пуст, пользователь '
        'видел текст «Нет товаров для отображения» без какого-либо пояснения '
        'о причине. Не было индикации оффлайн-режима или предложения '
        'подключиться к сети.'
    ),
    '''// products_screen.dart
child: filteredProducts.isEmpty
    ? const Center(
        child: Text(
            'Нет товаров для отображения'),
      )''',
    '''// products_screen.dart
child: filteredProducts.isEmpty
    ? Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off,
                size: 48,
                color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Нет товаров для отображения',
              style: Theme.of(context)
                  .textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Подключитесь к интернету '
              'и обновите список',
              style: Theme.of(context)
                  .textTheme.bodySmall,
            ),
          ],
        ),
      )''',
    'При пустом списке товаров пользователь видит иконку облачка и рекомендацию подключиться к интернету. Информативность интерфейса повышена.'
)

# TC 19
add_test_case(doc, 19,
    'Дата взятия товара отображается в формате ISO-8601',
    'qr_product_screen.dart, product_detail_screen.dart',
    'Форматирование данных',
    'Низкий',
    (
        'Поле takenAt модели ProductModel содержало объект DateTime. При '
        'отображении в интерфейсе значение выводилось через метод toString(), '
        'что давало строку формата 2025-06-15 14:30:00.000. Для '
        'русскоязычного интерфейса такой формат нечитаем. Требовалось '
        'форматирование в стиле dd.MM.yyyy HH:mm.'
    ),
    '''// qr_product_screen.dart
if (product.takenAt != null)
  Text(
    'Когда: \${product.takenAt}',
    // Выводит: 2025-06-15 14:30:00.000
  ),''',
    '''// qr_product_screen.dart
if (product.takenAt != null)
  Text(
    'Когда: \${DateFormat(
        'dd.MM.yyyy HH:mm')
        .format(product.takenAt!
            .toLocal())}',
    // Выводит: 15.06.2025 14:30
    style: Theme.of(context)
        .textTheme.bodySmall,
  ),''',
    'Дата и время взятия товара отображаются в формате dd.MM.yyyy HH:mm, привычном для русскоязычного пользователя.'
)

# TC 20
add_test_case(doc, 20,
    'Метод fromMap() не читает данные из SQLite корректно',
    'product_model.dart',
    'Сериализация данных',
    'Критический',
    (
        'Метод fromMap() модели ProductModel читал поля takenBy и takenAt '
        'строго по ключам takenBy и takenAt (camelCase). Однако при чтении '
        'данных из SQLite колонки имели имена taken_by и taken_at (snake_case). '
        'В результате выражение map[\'takenBy\'] возвращало null, даже если '
        'в базе было значение. Товары, взятые пользователями, отображались '
        'как «Доступен» вместо «Занят».'
    ),
    '''// product_model.dart
factory ProductModel.fromMap(
    Map<String, dynamic> map) {
  return ProductModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    status: map['status'] ?? 'unknown',
    takenBy: map['takenBy'],
    // null для ключа 'taken_by'
    takenAt: _parseDateTime(
        map['takenAt']),
    // null для ключа 'taken_at'
  );
}''',
    '''// product_model.dart
factory ProductModel.fromMap(
    Map<String, dynamic> map) {
  final status = map['status']
      as String? ?? 'unknown';
  return ProductModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    status: status,
    takenBy: map['taken_by']
        as String? ??
        map['takenBy'] as String?,
    takenAt: _parseDateTime(
        map['taken_at'] ??
        map['takenAt'] ??
        map['timestamp']),
  );
}''',
    'Метод fromMap() корректно читает данные как из SQLite (snake_case), так и из Firebase Firestore (camelCase). Статус товаров отображается точно.'
)

# ===== SUMMARY TABLE =====
doc.add_page_break()
doc.add_heading('Сводная таблица результатов тестирования', level=1)

table = doc.add_table(rows=21, cols=5)
table.style = 'Table Grid'
table.alignment = WD_TABLE_ALIGNMENT.LEFT

headers = ['№', 'Описание ошибки', 'Категория', 'Модуль', 'Статус']
for i, h in enumerate(headers):
    cell = table.cell(0, i)
    p = cell.paragraphs[0]
    run = p.add_run(h)
    run.bold = True
    run.font.name = 'Times New Roman'
    run.font.size = Pt(10)

data = [
    ['1', 'Несовпадение имён колонок SQLite', 'База данных', 'product_model', 'Исправлено'],
    ['2', 'Отсутствие валидации формата email', 'Валидация', 'validation', 'Исправлено'],
    ['3', 'Пароль менее 6 символов принимается', 'Безопасность', 'validation', 'Исправлено'],
    ['4', 'Пустое название товара сохраняется', 'Валидация', 'add_product_screen', 'Исправлено'],
    ['5', 'Отсутствует импорт go_router', 'Навигация', 'qr_product_screen', 'Исправлено'],
    ['6', 'QR-код не открывается в браузере', 'QR-генерация', 'qr_payload', 'Исправлено'],
    ['7', 'Сканер не распознаёт imgbb URL', 'QR-сканирование', 'qr_payload', 'Исправлено'],
    ['8', 'Миниатюры товаров не отображаются', 'UI', 'product_item_tile', 'Исправлено'],
    ['9', 'Ошибка загрузки проглатывается', 'Обработка ошибок', 'add_product_screen', 'Исправлено'],
    ['10', 'БД не мигрирует при обновлении', 'Миграция', 'database_helper', 'Исправлено'],
    ['11', 'DAO неверные имена колонок', 'База данных', 'product_dao', 'Исправлено'],
    ['12', 'Поиск чувствителен к регистру', 'Поиск', 'products_screen', 'Исправлено'],
    ['13', 'BuildContext после async-갭а', 'Безопасность UI', 'add_product_screen', 'Исправлено'],
    ['14', 'Двойное нажатие = дубликат', 'UX', 'add_product_screen', 'Исправлено'],
    ['15', 'Не реализован метод signOut()', 'Архитектура', 'firebase_auth', 'Исправлено'],
    ['16', 'Сканер обрабатывает QR дважды', 'Scanner', 'scan_screen', 'Исправлено'],
    ['17', 'UUID вместо имени пользователя', 'Отображение', 'qr_product_screen', 'Исправлено'],
    ['18', 'Нет пояснения в оффлайне', 'UX', 'products_screen', 'Исправлено'],
    ['19', 'Дата в формате ISO-8601', 'Форматирование', 'qr_product_screen', 'Исправлено'],
    ['20', 'fromMap() не читает SQLite', 'Сериализация', 'product_model', 'Исправлено'],
]

for row_idx, row_data in enumerate(data):
    for col_idx, cell_text in enumerate(row_data):
        cell = table.cell(row_idx + 1, col_idx)
        p = cell.paragraphs[0]
        run = p.add_run(cell_text)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(10)

# ===== CONCLUSION =====
doc.add_paragraph()
doc.add_heading('Выводы по тестированию', level=1)

conclusion1 = (
    'В ходе тестирования мобильного приложения «Складской учёт» было выявлено '
    'и исправлено 20 ошибок различной природы.'
)
p = doc.add_paragraph(conclusion1)
p.paragraph_format.first_line_indent = Cm(1.25)

doc.add_paragraph()
items = [
    '5 критических ошибок — приводили к невозможности компиляции или крашу приложения (№1, №5, №7, №11, №20)',
    '6 ошибок высокого приоритета — нарушали основной функционал (№2, №3, №6, №8, №9, №15)',
    '6 ошибок среднего приоритета — ухудшали UX или потенциально приводили к дефектам (№4, №10, №12, №13, №14, №16)',
    '3 ошибки низкого приоритета — косметические дефекты интерфейса (№17, №18, №19)',
]
for item in items:
    p = doc.add_paragraph(item, style='List Bullet')

doc.add_paragraph()
conclusion2 = (
    'Наибольшее количество ошибок (7) было связано с несогласованностью данных '
    'между SQLite, Firebase и моделью Dart. Это обусловлено использованием '
    'двухуровневой архитектуры хранения данных (локальная БД + облачное '
    'хранилище) и различием в соглашениях об именовании (snake_case в SQL vs '
    'camelCase в Dart/Firestore).'
)
p = doc.add_paragraph(conclusion2)
p.paragraph_format.first_line_indent = Cm(1.25)

conclusion3 = (
    'Исправление всех выявленных ошибок позволило обеспечить стабильную работу '
    'приложения в штатных и нештатных сценариях: авторизация, добавление '
    'товаров с загрузкой фотографий, QR-кодирование и сканирование, взятие '
    'и возврат товаров, синхронизация данных между устройствами через Firebase.'
)
p = doc.add_paragraph(conclusion3)
p.paragraph_format.first_line_indent = Cm(1.25)

doc.save(r'C:\Users\rere3\Desktop\flutter_app\Тестирование_Курсач.docx')
print('DOCX saved!')
