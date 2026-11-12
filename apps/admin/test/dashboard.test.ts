import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { dashboardMoney, deliverySuccess } from '../src/lib/dashboard';
void test('T-154 GMV keeps integer paise precision above Number safe range', () => {
 assert.equal(dashboardMoney('0'), '₹0.00');
 assert.equal(dashboardMoney('12345678'), '₹1,23,456.78');
 assert.equal(dashboardMoney('900719925474099301'), '₹9,00,71,99,25,47,40,993.01');
 for (const bad of ['-1','1.1','NaN','']) assert.throws(() => dashboardMoney(bad));
});
void test('T-154 success is explicit for empty and completed delivery attempts', () => {
 assert.equal(deliverySuccess(0,0),'No completed attempts');
 assert.equal(deliverySuccess(2,1),'66.7% (2 of 3)');
});
