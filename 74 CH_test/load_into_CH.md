[������ ��������� ClickHouse](https://habrahabr.ru/company/yandex/blog/303282/)

0. ��������� ������ �� ��������� ������
clickhouse-client

1. � CH ������� ������� �������, ������ mtcars

CREATE TABLE mtcars
(
    name  String,
    mpg Float32,
    cyl Float32,
    disp Float32,
    hp Float32,
    drat Float32,
    wt Float32,
    qsec Float32,
    vs Float32,
    am Float32,
    gear Int32,
    carb Int32
) ENGINE = Memory

������� [������](https://clickhouse.yandex/docs/ru/table_engines/index.html) �������� ������������

2. ��������� �� �������
SHOW TABLES

3. ��������� ������ � �������

��������� � ������� linux
@rem xz -v -c -d < ontime.csv.xz | clickhouse-client --query="INSERT INTO ontime FORMAT CSV"

cat mtcars.csv | clickhouse-client --query="INSERT INTO mtcars FORMAT CSV"

4. ��������� ��������� ������� � �� ���������� � �������
DESCRIBE TABLE mtcars
SELECT * FROM mtcars

SELECT * FROM mtcars

5. ��������� ������� � �������� �� ���������� ������:
http://10.0.0.234:8123/?query=SELECT%20*%20FROM%20mtcars

6. ��������� �� ��������� ������� (CREATE �� �������� ���� ������� �������)
SHOW CREATE TABLE mtcars


7. ������� �������
DROP TABLE mtcars


=====================================
������� ��������� ��� �������� csv
CREATE TABLE big_csv
(
    shopcode Float32,
    grpname String,
    barname String,
    barcode String,
    salesitem Float32,
    salesvalue Float32,
    adress String
) ENGINE = Memory

cat big_csv.csv | clickhouse-client --query="INSERT INTO big_csv FORMAT CSV"

===========================================
# ���������� ������� � �������

1. ������� �������� ������
select * from states where region!=''

3. ��������� ���������� ���������� ��������� ������

SELECT 
   uniq(serial) AS total_tv_box
FROM states


3. ������������ ������ �� ����� 1 ������ "������� �������"
df0 <- raw_df %>%
  group_by(programId) %>%
  summarise(unique_box=n_distinct(serial)) %>%
  arrange(desc(unique_box)), times=10)


SELECT 
   channelId, 
   region,
   type,
   programId,
   count(),
   sum(duration),
   uniq(serial),
   (
     SELECT 
        uniq(serial) 
      FROM states 
   ) AS total_tv_box,
   (
     SELECT 
        count() 
      FROM states 
   ) AS total_records
   FROM states
GROUP BY channelId, region, type, programId



   count(DISTINCT serial) ������������ � uniqExact(serial) :)

   SELECT uniq(serial) FROM states AS total_box

4. ��� �������� � ������� #3
SELECT 
   count()
FROM states

