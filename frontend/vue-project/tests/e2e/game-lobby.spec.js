import { test, expect } from '@playwright/test';
import { setupAuthenticatedUser } from './helpers/auth-setup.js'; 

test.describe('遊戲大廳頁面', () => {
  
  test.beforeEach(async ({ page }) => {
    // 每個測試前都設定已登入狀態
    await setupAuthenticatedUser(page);
  });
  
  test('顯示正確的頁面標題和用戶資訊', async ({ page }) => {
    // 前往大廳（因為有 baseURL，可以簡化成 /lobby）
    await page.goto('/lobby');
    
    // 驗證用戶暱稱
    await expect(page.locator('.nickname')).toHaveText('測試測試測試');
  });
  
  test('點擊登出按鈕會導向登入頁', async ({ page }) => {
    await page.goto('/lobby');
    
    // 攔截登出 API
    await page.route('**/auth/logout', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ message: 'Logged out' })
      });
    });
    
    // 點擊登出
    await page.click('.logout-btn');
    
    // 應該導向首頁（因為有 baseURL，可以簡化）
    await expect(page).toHaveURL('');
  });
});
