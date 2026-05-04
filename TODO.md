你这个 DOM 是 AG Grid 的一行：

<div role="row" row-index="2">
  <div role="gridcell" col-id="Name">legal_exp</div>
  <div role="gridcell" col-id="Type">Number</div>
  <div role="gridcell" col-id="Required">...</div>
  <div role="gridcell" col-id="Value">
    <span class="number-cell">0.0000000000</span>
  </div>
</div>

你的目标是：

找到 Name == legal_exp 的那一行，然后编辑同一行 Value 列里的 0.00000

核心逻辑不是直接按 0.00000 找，而是：

row[Name == "legal_exp"] -> same row -> Value cell -> edit

⸻

方案 1：用 XPath 精准定位同一行的 Value cell

from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
wait = WebDriverWait(driver, 20)
name = "legal_exp"
new_value = "50"
# 找到 Name 列文本为 legal_exp 的那一整行
row = wait.until(EC.presence_of_element_located((
    By.XPATH,
    f"//div[@role='row'][.//div[@col-id='Name' and normalize-space()='{name}']]"
)))
# 在同一行里找到 Value 列
value_cell = row.find_element(By.XPATH, ".//div[@col-id='Value']")
# 双击进入编辑
ActionChains(driver).double_click(value_cell).perform()
# 当前 active element 通常就是 AG Grid 创建出来的 input
editor = driver.switch_to.active_element
# 全选并输入新值
editor.send_keys(Keys.CONTROL, "a")
editor.send_keys(new_value)
editor.send_keys(Keys.ENTER)

这是最推荐的第一版。

⸻

方案 2：如果双击后没有进入编辑，用 click + Enter

有些 AG Grid 配置是单击选中，按 Enter 才进入编辑。

value_cell.click()
ActionChains(driver)\
    .send_keys(Keys.ENTER)\
    .send_keys(Keys.CONTROL, "a")\
    .send_keys("50")\
    .send_keys(Keys.ENTER)\
    .perform()

完整写法：

row = wait.until(EC.presence_of_element_located((
    By.XPATH,
    "//div[@role='row'][.//div[@col-id='Name' and normalize-space()='legal_exp']]"
)))
value_cell = row.find_element(By.XPATH, ".//div[@col-id='Value']")
value_cell.click()
actions = ActionChains(driver)
actions.send_keys(Keys.ENTER)
actions.send_keys(Keys.CONTROL, "a")
actions.send_keys("50")
actions.send_keys(Keys.ENTER)
actions.perform()

⸻

方案 3：更稳的函数封装

你可以写成一个通用函数：

from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
def edit_ag_grid_value_by_name(driver, name: str, new_value: str, timeout: int = 20):
    wait = WebDriverWait(driver, timeout)
    row_xpath = (
        f"//div[@role='row']"
        f"[.//div[@role='gridcell' and @col-id='Name' and normalize-space()='{name}']]"
    )
    row = wait.until(EC.presence_of_element_located((By.XPATH, row_xpath)))
    value_cell = row.find_element(
        By.XPATH,
        ".//div[@role='gridcell' and @col-id='Value']"
    )
    driver.execute_script(
        "arguments[0].scrollIntoView({block: 'center', inline: 'center'});",
        value_cell
    )
    wait.until(EC.element_to_be_clickable(value_cell))
    # 先尝试双击编辑
    ActionChains(driver).double_click(value_cell).perform()
    editor = driver.switch_to.active_element
    editor.send_keys(Keys.CONTROL, "a")
    editor.send_keys(str(new_value))
    editor.send_keys(Keys.ENTER)
    return True

调用：

edit_ag_grid_value_by_name(driver, "legal_exp", "50")

⸻

方案 4：如果 AG Grid 行很多，需要先滚动到 legal_exp

AG Grid 是虚拟滚动表格，DOM 里只存在当前可见的行。
也就是说，如果 legal_exp 不在当前 viewport 里，XPath 会找不到。

这种情况下需要滚动 grid body，直到该行出现。

示例：

from selenium.common.exceptions import TimeoutException, NoSuchElementException
from selenium.webdriver.common.by import By
import time
def find_ag_grid_row_by_name_with_scroll(driver, name: str, max_scrolls: int = 80):
    row_xpath = (
        f"//div[@role='row']"
        f"[.//div[@role='gridcell' and @col-id='Name' and normalize-space()='{name}']]"
    )
    viewport = driver.find_element(By.CSS_SELECTOR, ".ag-body-viewport")
    for _ in range(max_scrolls):
        rows = driver.find_elements(By.XPATH, row_xpath)
        if rows:
            return rows[0]
        driver.execute_script("arguments[0].scrollTop += 300;", viewport)
        time.sleep(0.1)
    raise NoSuchElementException(f"Cannot find AG Grid row with Name = {name}")

然后结合编辑：

def edit_ag_grid_value_by_name_scroll(driver, name: str, new_value: str):
    row = find_ag_grid_row_by_name_with_scroll(driver, name)
    value_cell = row.find_element(By.XPATH, ".//div[@col-id='Value']")
    driver.execute_script(
        "arguments[0].scrollIntoView({block: 'center', inline: 'center'});",
        value_cell
    )
    ActionChains(driver).double_click(value_cell).perform()
    editor = driver.switch_to.active_element
    editor.send_keys(Keys.CONTROL, "a")
    editor.send_keys(str(new_value))
    editor.send_keys(Keys.ENTER)

调用：

edit_ag_grid_value_by_name_scroll(driver, "legal_exp", "50")

⸻

关键点解释

你截图里的这一行：

<div role="gridcell" col-id="Name">legal_exp</div>

和这个：

<div role="gridcell" col-id="Value">
    <span class="number-cell">0.0000000000</span>
</div>

是同一个父级 row 下面的兄弟 cell。

所以 XPath 应该从 row 级别定位：

//div[@role='row'][.//div[@col-id='Name' and normalize-space()='legal_exp']]

然后在这个 row 内找：

.//div[@col-id='Value']

不要直接用：

//span[text()='0.0000000000']

因为页面里可能有很多个 0.0000000000，容易改错。

⸻

如果是 Mac，CTRL + A 可能不生效

如果你在 Mac 上跑 Selenium，浏览器里全选有时需要 COMMAND + A：

from selenium.webdriver.common.keys import Keys
import platform
select_key = Keys.COMMAND if platform.system() == "Darwin" else Keys.CONTROL
editor.send_keys(select_key, "a")
editor.send_keys("50")
editor.send_keys(Keys.ENTER)

⸻

最终推荐版本

from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
import platform
def edit_legal_exp(driver, new_value):
    wait = WebDriverWait(driver, 20)
    row = wait.until(lambda d: d.find_element(
        By.XPATH,
        "//div[@role='row'][.//div[@role='gridcell' and @col-id='Name' and normalize-space()='legal_exp']]"
    ))
    value_cell = row.find_element(
        By.XPATH,
        ".//div[@role='gridcell' and @col-id='Value']"
    )
    driver.execute_script(
        "arguments[0].scrollIntoView({block: 'center', inline: 'center'});",
        value_cell
    )
    ActionChains(driver).double_click(value_cell).perform()
    editor = driver.switch_to.active_element
    select_key = Keys.COMMAND if platform.system() == "Darwin" else Keys.CONTROL
    editor.send_keys(select_key, "a")
    editor.send_keys(str(new_value))
    editor.send_keys(Keys.ENTER)

调用：

edit_legal_exp(driver, 50)

如果你是在 ASAP2 / AG Grid 这种页面里操作，这个思路基本就是正确方向：先锁定 Name，再编辑同 row 的 Value。
