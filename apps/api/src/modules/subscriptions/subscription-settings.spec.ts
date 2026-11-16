// T-075 / FR-075: exact litre storage at the ml boundary, independent of JS floats.
import { capacityLitres, capacityMl } from './subscription-settings.service';
describe('T-075 exact capacity conversion',()=>{
  it('roundtrips positive fractional litres, maximum and null without rounding',()=>{
    for(const [litres,ml] of [['0.001',1],['1.5',1500],['2147483.647',2147483647]] as const) {
      expect(capacityMl(litres)).toBe(ml);expect(capacityLitres(ml)).toBe(litres);
    }
    expect(capacityMl('1.500')).toBe(1500);expect(capacityLitres(null)).toBeNull();
    for(const invalid of ['0','0.000','-1','01','0.0001','2147483.648','9999999','1e3','NaN',' 1','1.']) expect(()=>capacityMl(invalid)).toThrow();
  });
});
