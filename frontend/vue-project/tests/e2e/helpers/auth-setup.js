// tests/helpers/auth-setup.js
export async function setupAuthenticatedUser(page) {
  await page.goto('http://localhost:5173/');
  
  await page.evaluate(() => {
    localStorage.setItem('accessToken', 'test_access_token_123');
    localStorage.setItem('refresh_token', 'test_refresh_token_123');
  });
  
  await page.route('**/auth/me', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        user: {
          id: 1,
          email: 'test@example.com',
          name: '測試測試測試',
          avatar_url: null
        }
      })
    });
  });
}
