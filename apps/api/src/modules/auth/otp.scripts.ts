// Redis TIME is authoritative. All touched keys use one hash slot; each
// reservation/verification is atomic across API replicas (ADR-011 / RULE-19).
export const RESERVE_OTP = `
local t = redis.call('TIME')
local now = tonumber(t[1]) * 1000 + math.floor(tonumber(t[2]) / 1000)
local retry = 0
local untilMs = tonumber(redis.call('HGET', KEYS[5], 'untilMs') or '0')
retry = math.max(retry, untilMs - now)
local limits = {5, 20, tonumber(ARGV[2])}
for i = 2, 4 do
  redis.call('ZREMRANGEBYSCORE', KEYS[i], '-inf', now - 3600000)
  if redis.call('ZCARD', KEYS[i]) >= limits[i - 1] then
    local oldest = redis.call('ZRANGE', KEYS[i], 0, 0, 'WITHSCORES')
    retry = math.max(retry, tonumber(oldest[2]) + 3600000 - now)
  end
end
local last = redis.call('ZREVRANGE', KEYS[2], 0, 0, 'WITHSCORES')
if #last > 0 then retry = math.max(retry, tonumber(last[2]) + 30000 - now) end
if retry > 0 then return {'RATE_LIMITED', tostring(math.ceil(retry / 1000))} end
for i = 2, 4 do
  redis.call('ZADD', KEYS[i], now, ARGV[1])
  redis.call('PEXPIRE', KEYS[i], 3600000)
end
redis.call('SET', KEYS[1], ARGV[3], 'PX', 300000)
return {'OK'}
`;

export const CHANGE_OTP = `
local raw = redis.call('GET', KEYS[1])
if not raw then return 0 end
local data = cjson.decode(raw)
if data.revision ~= ARGV[1] then return 0 end
if ARGV[2] == 'discard' then redis.call('DEL', KEYS[1]); return 1 end
data.status = 'ACTIVE'
redis.call('SET', KEYS[1], cjson.encode(data), 'KEEPTTL')
return 1
`;

export const CONSUME_OTP = `
local raw = redis.call('GET', KEYS[1])
if not raw then return {'OTP_EXPIRED'} end
local data = cjson.decode(raw)
if data.revision ~= ARGV[1] then return {'OTP_INVALID'} end
if data.status == 'EXHAUSTED' then return {'OTP_ATTEMPTS_EXCEEDED'} end
if data.status ~= 'ACTIVE' then return {'OTP_INVALID'} end
if ARGV[2] == 'true' then
  redis.call('DEL', KEYS[1])
  return {'OK'}
end
data.attempts = data.attempts + 1
if data.attempts >= 5 then
  data.status = 'EXHAUSTED'
  local t = redis.call('TIME')
  local now = tonumber(t[1]) * 1000 + math.floor(tonumber(t[2]) / 1000)
  local streak = redis.call('HINCRBY', KEYS[2], 'streak', 1)
  local delay = math.min(tonumber(ARGV[4]), tonumber(ARGV[3]) * 2 ^ math.min(streak - 1, 30))
  redis.call('HSET', KEYS[2], 'untilMs', now + delay * 1000)
  redis.call('EXPIRE', KEYS[2], 3600)
end
redis.call('SET', KEYS[1], cjson.encode(data), 'KEEPTTL')
if data.status == 'EXHAUSTED' then return {'OTP_ATTEMPTS_EXCEEDED'} end
return {'OTP_INVALID'}
`;
