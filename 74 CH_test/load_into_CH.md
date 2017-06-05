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

4. ��������� ������� � �������
SELECT * FROM mtcars

5. ��������� ������� � �������� �� ���������� ������:
http://10.0.0.234:8123/?query=SELECT%20*%20FROM%20mtcars

3. ������� �������
DROP TABLE mtcars