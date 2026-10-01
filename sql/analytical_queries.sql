-- ====================================================================
-- Проект: Анализ дебиторской задолженности и производственного брака
-- Описание: Валидация данных, проверка сходимости показателей 
--           и расчет ключевых бизнес-метрик перед интеграцией в BI
-- ====================================================================

-- 1. Анализ финансовых потерь от брака по видам продукции
-- Назначение: Сквозная связка выпуска и справочника для оценки убытков
SELECT 
    p.product_name,                            -- Название продукции
    SUM(fp.qty_produced) AS total_produced,    -- Всего выпущено, шт.
    SUM(fp.qty_rejected) AS total_defects,     -- Объем брака, шт.
    SUM(fp.qty_rejected * fp.unit_cost) AS total_financial_loss -- Убытки, ₽
FROM 
    public.fact_production fp
JOIN 
    public.spr_products p ON fp.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    total_financial_loss DESC;


-- 2. Скоринг контрагентов и анализ платежной дисциплины
-- Назначение: Оценка объема задолженности и рисков по группам клиентов
SELECT 
    c.client_name,                             -- Название компании
    c.reliability_category,                    -- Категория надежности (A, B, C)
    SUM(fd.invoice_amount) AS total_invoice_sum, -- Общая сумма счетов, ₽
    SUM(fd.debt_amount) AS total_debt_balance,   -- Остаток долга, ₽
    MAX(fd.delay_days) AS max_delay_days,        -- Максимальная просрочка, дней
    SUM(fd.penalty_amount) AS total_penalties    -- Сумма начисленных штрафов, ₽
FROM 
    public.fact_debts fd
JOIN 
    public.spr_clients c ON fd.client_id = c.client_id
GROUP BY 
    c.client_name, 
    c.reliability_category
ORDER BY 
    total_debt_balance DESC;


-- 3. Динамика потерь от брака по датам
-- Назначение: Поиск временных аномалий и сезонных пиков брака
SELECT 
    fp.report_date, 
    SUM(fp.qty_rejected) AS total_defects,
    SUM(fp.qty_rejected * fp.unit_cost) AS financial_loss
FROM 
    public.fact_production fp
GROUP BY 
    fp.report_date
ORDER BY 
    fp.report_date;


-- 4. Распределение задолженности по интервалам просрочки (Aging Analysis)
-- Назначение: Группировка долгов для оценки краткосрочных и долгосрочных рисков
SELECT 
    CASE 
        WHEN fd.delay_days = 0 THEN '1. Нет просрочки'
        WHEN fd.delay_days BETWEEN 1 AND 10 THEN '2. 1-10 дней'
        WHEN fd.delay_days BETWEEN 11 AND 30 THEN '3. 11-30 дней'
        ELSE '4. Более 30 дней'
    END AS overdue_interval,
    SUM(fd.debt_amount) AS total_debt_in_interval
FROM 
    public.fact_debts fd
GROUP BY 
    overdue_interval
ORDER BY 
    overdue_interval;