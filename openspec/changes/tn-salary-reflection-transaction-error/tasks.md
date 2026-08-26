## 1. Transaction ownership in ЗаписатьРабочийОбъект

- [x] 1.1 Open a transaction only when none is active
- [x] 1.2 Roll back only the transaction opened here
- [x] 1.3 Skip protocol DB writes while an outer transaction is still active

## 2. Preserve original exception

- [x] 2.1 Re-raise from ОбработатьКорректировкиПоПараметрам when a transaction is active
- [x] 2.2 Include fill/write in the same try so a poisoned transaction does not continue with another query
