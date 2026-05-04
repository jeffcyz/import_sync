你不能在 selector 里硬编码 05/26/2026，那就应该先定位这个 Processing Date 组件本身，再从它内部读取当前选中的文本。

从截图看结构大概是：

<span class="payment-date">Processing Date</span>
<div class="ant-select ... payment-date ...">
  ...
  <span class="ant-select-selection-item" title="05/26/2026">
    05/26/2026
  </span>
</div>

所以正确思路是：

找到 label = Processing Date
→ 找到它后面的 ant-select
→ 读取 ant-select-selection-item 的 text 或 title

⸻

推荐写法 1：通过 Processing Date label 定位

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
wait = WebDriverWait(driver, 20)
processing_date_el = wait.until(EC.presence_of_element_located((
    By.XPATH,
    "//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
    "/following-sibling::div[contains(@class,'ant-select')][1]"
    "//span[contains(@class,'ant-select-selection-item')]"
)))
processing_date_text = processing_date_el.text.strip()
print(processing_date_text)

输出：

05/26/2026

⸻

推荐写法 2：读取 title 属性，更稳定

Ant Design 的 Select 当前值经常同时存在于：

<span class="ant-select-selection-item" title="05/26/2026">
    05/26/2026
</span>

所以你也可以直接读 title：

processing_date_el = wait.until(EC.presence_of_element_located((
    By.XPATH,
    "//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
    "/following-sibling::div[contains(@class,'ant-select')][1]"
    "//span[contains(@class,'ant-select-selection-item')]"
)))
processing_date = processing_date_el.get_attribute("title") or processing_date_el.text
processing_date = processing_date.strip()
print(processing_date)

这个比只读 .text 更稳。

⸻

推荐写法 3：封装成函数

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
def get_processing_date(driver, timeout=20):
    wait = WebDriverWait(driver, timeout)
    item = wait.until(lambda d: d.find_element(
        By.XPATH,
        "//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
        "/following-sibling::div[contains(@class,'ant-select')][1]"
        "//span[contains(@class,'ant-select-selection-item')]"
    ))
    value = item.get_attribute("title") or item.text
    return value.strip()

调用：

processing_date = get_processing_date(driver)
print(processing_date)

⸻

如果页面里有多个 modal，建议限制在当前打开的 modal 内

因为 Ant Design modal 可能会保留旧 DOM。更稳的是先锁定当前可见的 dialog：

modal = wait.until(EC.presence_of_element_located((
    By.XPATH,
    "//div[@role='dialog' and @aria-modal='true']"
)))
processing_date_el = modal.find_element(
    By.XPATH,
    ".//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
    "/following-sibling::div[contains(@class,'ant-select')][1]"
    "//span[contains(@class,'ant-select-selection-item')]"
)
processing_date = (
    processing_date_el.get_attribute("title")
    or processing_date_el.text
).strip()
print(processing_date)

⸻

如果 .text 为空，用 JavaScript 读取

有些 Ant Design 元素会因为 overlay、opacity、readonly 等原因导致 .text 读不到。可以用 JS：

processing_date = driver.execute_script(
    "return arguments[0].textContent;",
    processing_date_el
).strip()
print(processing_date)

或者优先读 title：

processing_date = driver.execute_script(
    "return arguments[0].getAttribute('title') || arguments[0].textContent;",
    processing_date_el
).strip()

⸻

最稳版本

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
def get_processing_date_from_modal(driver, timeout=20):
    wait = WebDriverWait(driver, timeout)
    modal = wait.until(lambda d: d.find_element(
        By.XPATH,
        "//div[@role='dialog' and @aria-modal='true']"
    ))
    date_item = modal.find_element(
        By.XPATH,
        ".//span[contains(@class,'payment-date') and normalize-space()='Processing Date']"
        "/following-sibling::div[contains(@class,'ant-select')][1]"
        "//span[contains(@class,'ant-select-selection-item')]"
    )
    value = driver.execute_script(
        "return arguments[0].getAttribute('title') || arguments[0].textContent;",
        date_item
    )
    return value.strip()

调用：

processing_date = get_processing_date_from_modal(driver)
print(processing_date)

⸻

关键是不要这样写：

driver.find_element(By.XPATH, "//*[text()='05/26/2026']")

因为你现在就是不知道日期是什么。

应该用稳定的上下文：

//span[normalize-space()='Processing Date']

然后找它旁边的当前选中值：

/following-sibling::div[contains(@class,'ant-select')][1]//span[contains(@class,'ant-select-selection-item')]
