library(magrittr)
library(tibble)
library(dplyr)
library(Rmpfr)



options(digits=22)

# ========== ����������	������ ���������
p1 <- 0.99999768
p2 <- p1
p3 <- 0.99999
p4 <- p3
p5 <- 0.99986592
p6 <- p5
p7 <- 0.99999
(p1+p2-p1*p2)*(p3+p4-p3*p4)*(p5+p6-p5*p6)*p7

# === ������� ����������� ������� ����������
elems <- mpfr(c(8, 3, 2, 2, 5, 1), 512)
# 1 - prod((1 - 0.9998670)^elems)
composite <- 1. - (1. - 0.9998670)^elems
print(composite, digits=22)

# p_c (t)=[p_1 (t)+p_2 (t)-p_1 (t)p_2 (t)]�[p_3 (t)+p_4 (t)-p_3 (t)p_4 (t)]�p_5 (t)�p_6 (t)[p_5 (t)+p_6 (t)-p_5 (t)p_6 (t)]�p_7 (t)�p_8 (t)
# =================================================
# ������� ��� 72 ����� MTTR
# ������������� AR2240	1, 2
# ���������� CE6851	3, 4
# ���������� S5320	5, 6
# ���������� SNS2224	7, 8
# ��� OceanStor 5500 (��)	12
# ��� OceanStor 5500 (����)	12
# ��� ���� 11
# app 10
# virt 9

  
p1 <- 0.9997261
p2 <- p1
p3 <- 0.9998325
p4 <- p3
p5 <- 0.9998756
p6 <- p5
p7 <- 0.9998756
p8 <- p7


# - ������� ��� ��
p9 <- 0.999999
p10 <- 0.999999 
p11 <- 0.999999
p12 <- 0.9995298

(p1+p2-p1*p2)*(p3+p4-p3*p4)*(p5+p6-p5*p6)*(p7+p8-p7*p8)*p9*p10*p11*p12

# - ������� ��� ����
p3 <- 1
p4 <- p1
p9 <- 0.999999
p10 <- 0.999999 
p11 <- 1
p12 <- 0.9995049

(p1+p2-p1*p2)*(p3+p4-p3*p4)*(p5+p6-p5*p6)*(p7+p8-p7*p8)*p9*p10*p11*p12


# === ������� FITS ��� N+1 ������
fits <- 1142 # ������������� ������� �� 10^9 ����� ������ ���������� (Failures in Time)
mtbf <- 10^9/fits # � �����
# n+1 ����
n <- 2 # ����� ������
harm <- 1/(1:(n))

ext <- sum(harm)
mtbf_n <- mtbf * ext
fits_n <- 10^9 / mtbf_n 

mtbf_n_year <- mtbf_n/(365*24)

mttr_value <- c(1, 4, 24, 72) # ������� ����� � ����� �� ��������������

# == ������ rh1288
rh1288 <- tibble(type=c("����������� �����", "RAID ����������", "���������", "����������� ������", 
                        "���� �������", "������� ����"),
                 mtbf=c(28.3, 204.1, 1426.9, 95.1, 157.5, 3306)) # mtbf ������ � �����

rh1288 <- tibble(mtbf=c(28.3,
                        50.0,
                        85.6,
                        408.6,
                        204.1,
                        472.6,
                        472.6,
                        6687.1,
                        4280.8
))
# ������� mtbf ��� ������� rh1288
mtbf1_series <- 1 / sum(1/rh1288$mtbf)

server_rh1288 <- tibble(mttr=mttr_value, 
                        availability=mtbf1_series / (mtbf1_series + mttr_value/(24*365)), # ��������� ���� ������� � ����
                        downtime=(1-availability)*365*24*60) # ������� ������� � ������� � ���

dput(server_rh1288)
  
# == ������ rh2288
#

# =================================
# http://www.pixelbeat.org/docs/reliability_calculator/
# Availability = 	MTBF / (MTBF + MTTR)
# Downtime per year =	(1 - Availability) x 1 year
# Series MTBF	= 1 / (1/MTBF1 + .. + 1/MTBFn)
# Series Availability	= A1 x A2 x .. x An
# Series Downtime	= (1 - Series Availability) x 1 year	
# Parallel MTBF =	MTBF x (1 + 1/2 + ... + 1/n)
# Parallel Availability =	1 - (1-A)n
# Parallel Downtime	= (1- Parallel Availability) x 1 year	

# =======================================
325*150*30 *100 
.Last.value *256 / (1024 * 1024 *1024)
  

# ������� AFR ��� ����������� =====
# == ������ rh2288
rh2288 <- tibble(type=c("����������� �����", "RAID ����������", "���������", 
                        "����������� ������", "���� ������", "����������",
                        "������� ����", "���� �������"),
                 fits=c(4035, 559, 140,
                        50, 82.9, 582,
                        3425, 2000)) # mtbf ������ � �����
# fits -- ������������� ������� �� 10^9 ����� ������ ���������� (Failures in Time)

# AFR = 1-exp(-8760/MTBF{� �����})
rh2288 %<>% mutate(mtbf=10^9/fits) %>% # ������� ��������� �� ����� � �����
  mutate(afr=(1-exp(-8760/mtbf))*100) %>% # annual falure rate � %
  mutate(afr10=afr*10) # � �� 10 ���?

stop()

# �������� ������ �� ������������

df <- NULL

# �������� ������� ���������� � ������������ ��� =========

# == ������ rh2288
df <- 
  tribble(
    ~element, ~n, ~fits,
    "����������� �����", 1, 4035.2,
    "RAID ����������", 1, 559.2,
    "���������", 2, 40,
    "����������� ������", 24, 50,
    "���� ������", 1, 82.9,
    "����������", 8, 582,
    "������� ����", 12, 3425, 
    "���� �������", 2, 2000, 
    "������� �����", 2, 362.3
  )

tibble(type=c(
),
n=c(),
fits=c(4035, 559, 140,
       50, 82.9, 582,
       3425, 2000)) # mtbf ������ � �����
# fits -- ������������� ������� �� 10^9 ����� ������ ���������� (Failures in Time)

# AFR = 1-exp(-8760/MTBF{� �����})
rh2288 %<>% mutate(mtbf=10^9/fits) %>% # ������� ��������� �� ����� � �����
  mutate(afr=(1-exp(-8760/mtbf))*100) %>% # annual falure rate � %
  mutate(afr10=afr*10) # � �� 10 ���?

stop()

