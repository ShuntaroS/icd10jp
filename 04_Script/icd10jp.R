# Set up ------------------------------------------------------------------

library(pacman)
p_load(tidyverse, tidylog, touch, openxlsx)


# ICD10コード（日本語含む）読み込み -----------------------------------------------------

df00_icd10 <- openxlsx::read.xlsx("01_Data/kihon2013.xlsx", sheet = "基本分類表データ")

# 必要なデータ作成

df01_icd10 <- df00_icd10 |> 
  filter(str_detect(`種別`, pattern = '章') == FALSE) |> 
  filter(str_detect(`種別`, pattern = '中') == FALSE) |> 
  select(`中間分類ブンルイ`, `３桁分類ブンルイ`, `コード`, `剣星ホシ`, `コード名`) |> 
  rename(
    cat_middle = `中間分類ブンルイ`,
    cat_3 = `３桁分類ブンルイ`,
    code_icd10_p = `コード`,
    star = `剣星ホシ`,
    codename = `コード名`
  )

# 大分類の取得
high_code <- df01_icd10 |> 
  filter(str_length(cat_3) >= 7) |> 
  rename(codename_high = codename) |> 
  select(cat_middle, codename_high)

df02_icd10 <- left_join(df01_icd10, high_code, by = "cat_middle")|> 
  filter(str_length(cat_3) != 7) |> 
  mutate(star = if_else(star == "†", 1, 0)) |> 
  mutate(code_icd10 = str_replace(code_icd10_p, pattern = "\\.", replace = ""))

# ICD9と紐付け
df03_icd10 <- df02_icd10 |> 
  mutate(code_icd9 = icd_map(code_icd10_p, from = 10, to = 9)) |> 
  select(cat_middle, cat_3, code_icd10_p, code_icd10, codename_high, codename, code_icd9)


# Output ------------------------------------------------------------------

write_rds(df03_icd10, "03_Output/icd10code.rds")
write_csv(df03_icd10, "03_Output/icd10code.csv")
write.xlsx(df03_icd10, "03_Output/icd10code.xlsx")
