这是 Ant Design Select dropdown，不是普通 <select>，所以不能用 Selenium 的 Select()。要用 点击 selector → 输入/搜索 → 点击下拉 option 的方式。

你的目标应该是：

定位 Processing Date 这个 ant-select
→ click 打开 dropdown
→ 输入目标日期，比如 05/26/2026
→ 点击下拉项

推荐函数：按 label 设置 Processing Date

from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
def set_processing_date(driver, target_date: str, timeout: int = 20):
    wait = WebDriverWait(driver, timeout)
    # 1. 锁定当前打开的 modal
    modal = wait.until(EC.presence_of_element_located((
        By.XPATH,
        "//div[@role='dialog' and @aria-modal='true']"
    )))
    # 2. 找到 Processing Date 后面的 ant-select
    select_box = modal.find_element(
        By.XPATH,
        ".//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
        "/following-sibling::div[contains(@class,'ant-select')][1]"
    )
    # 3. 点击打开 dropdown
    driver.execute_script(
        "arguments[0].scrollIntoView({block: 'center', inline: 'center'});",
        select_box
    )
    select_box.click()
    # 4. 找到 ant-select 内部的 search input
    input_el = wait.until(EC.presence_of_element_located((
        By.XPATH,
        "//input[contains(@class,'ant-select-selection-search-input') "
        "and @role='combobox']"
    )))
    # 5. 输入目标日期
    input_el.send_keys(Keys.CONTROL, "a")
    input_el.send_keys(target_date)
    # 6. 点击 dropdown 里匹配的 option
    option = wait.until(EC.element_to_be_clickable((
        By.XPATH,
        "//div[contains(@class,'ant-select-dropdown') and not(contains(@style,'display: none'))]"
        f"//div[contains(@class,'ant-select-item-option') "
        f"and .//div[normalize-space()='{target_date}' or normalize-space()='{target_date}']]"
    )))
    option.click()
    # 7. 可选：确认值已经被设置
    selected_item = select_box.find_element(
        By.XPATH,
        ".//span[contains(@class,'ant-select-selection-item')]"
    )
    selected_value = (
        selected_item.get_attribute("title")
        or selected_item.text
    ).strip()
    if selected_value != target_date:
        raise RuntimeError(
            f"Processing Date was not set correctly. "
            f"Expected {target_date}, got {selected_value}"
        )
    return selected_value

调用：

set_processing_date(driver, "05/26/2026")

⸻

如果输入后 dropdown 不过滤，直接点击 option

有些 Ant Design dropdown 是只读输入框，input 虽然存在，但 readonly。这种情况下先打开 dropdown，然后直接找 option：

def set_processing_date_no_typing(driver, target_date: str, timeout: int = 20):
    wait = WebDriverWait(driver, timeout)
    modal = wait.until(EC.presence_of_element_located((
        By.XPATH,
        "//div[@role='dialog' and @aria-modal='true']"
    )))
    select_box = modal.find_element(
        By.XPATH,
        ".//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
        "/following-sibling::div[contains(@class,'ant-select')][1]"
    )
    select_box.click()
    option = wait.until(EC.element_to_be_clickable((
        By.XPATH,
        "//div[contains(@class,'ant-select-dropdown') and not(contains(@style,'display: none'))]"
        f"//div[contains(@class,'ant-select-item-option') and normalize-space()='{target_date}']"
    )))
    option.click()

⸻

如果 option 不在当前可见列表里，需要键盘选择

如果 dropdown 打开后，你能输入日期，但 Selenium 找不到 option，可以用 Enter 提交当前高亮项：

def set_processing_date_by_keyboard(driver, target_date: str, timeout: int = 20):
    wait = WebDriverWait(driver, timeout)
    modal = wait.until(EC.presence_of_element_located((
        By.XPATH,
        "//div[@role='dialog' and @aria-modal='true']"
    )))
    select_box = modal.find_element(
        By.XPATH,
        ".//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
        "/following-sibling::div[contains(@class,'ant-select')][1]"
    )
    select_box.click()
    input_el = wait.until(EC.presence_of_element_located((
        By.XPATH,
        "//input[contains(@class,'ant-select-selection-search-input') and @role='combobox']"
    )))
    input_el.send_keys(Keys.CONTROL, "a")
    input_el.send_keys(target_date)
    input_el.send_keys(Keys.ENTER)

⸻

更适合你当前截图的简化版

你的这个 input 是：

<input
  type="search"
  role="combobox"
  readonly
  unselectable="on"
  class="ant-select-selection-search-input"
>

这里有一个重要信息：

readonly

所以它大概率不能直接 send_keys 输入。你需要：

select_box.click()
option.click()

也就是用 dropdown 选，而不是往 input 里打字。

推荐你先用这个：

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
def choose_processing_date(driver, target_date: str, timeout: int = 20):
    wait = WebDriverWait(driver, timeout)
    modal = wait.until(EC.presence_of_element_located((
        By.XPATH,
        "//div[@role='dialog' and @aria-modal='true']"
    )))
    select_box = modal.find_element(
        By.XPATH,
        ".//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
        "/following-sibling::div[contains(@class,'ant-select')][1]"
    )
    driver.execute_script(
        "arguments[0].scrollIntoView({block: 'center'});",
        select_box
    )
    select_box.click()
    option = wait.until(EC.element_to_be_clickable((
        By.XPATH,
        "//div[contains(@class,'ant-select-dropdown') and not(contains(@class,'ant-select-dropdown-hidden'))]"
        f"//div[contains(@class,'ant-select-item-option') and normalize-space()='{target_date}']"
    )))
    option.click()
    return target_date

调用：

choose_processing_date(driver, "05/26/2026")

⸻

如果点击 option 失败，用 JavaScript click

Ant Design dropdown 经常有遮挡或动画，普通 .click() 有时会失败：

driver.execute_script("arguments[0].click();", option)

替换这里：

option.click()

为：

driver.execute_script("arguments[0].click();", option)

⸻

如果日期不是固定输入，而是想选择下一个 Processing Date

你可以先打开 dropdown，然后读取所有 option：

select_box.click()
options = wait.until(EC.presence_of_all_elements_located((
    By.XPATH,
    "//div[contains(@class,'ant-select-dropdown') and not(contains(@class,'ant-select-dropdown-hidden'))]"
    "//div[contains(@class,'ant-select-item-option')]"
)))
dates = [o.text.strip() for o in options if o.text.strip()]
print(dates)

然后选择第一个：

options[0].click()

或者选择最后一个：

options[-1].click()

⸻

你这个元素最关键的判断是：

readonly

所以这类 Ant Design dropdown 通常不是“输入框赋值”，而是：

click select → click option

而不是：

send_keys 到 input
