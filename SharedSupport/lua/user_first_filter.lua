-- user_first_filter.lua
-- 用户输入记忆词优先（将曾经选过上屏的用户词汇与自造词提前到普通词典之前）
-- 
-- 配置项（可在方案的 user_first_filter: 下配置）：
--   enabled: true / false   (默认 true，是否启用记忆词优先)
--   max_count: 2            (默认 2，最多提前多少个用户记忆词)
--   scan_limit: 60          (默认 60，候选扫描窗口深度)

local M = {}

local is_user_cand = {
    user_table = true,
    user_phrase = true,
}

function M.init(env)
    local config = env.engine.schema.config
    local ns = env.name_space:gsub("^*", "")
    
    local enabled = config:get_bool(ns .. "/enabled")
    if enabled == nil then
        enabled = true
    end
    M.enabled = enabled
    M.max_count = config:get_int(ns .. "/max_count") or 2
    M.scan_limit = config:get_int(ns .. "/scan_limit") or 60
end

function M.func(input, env)
    if not M.enabled then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local high_quality_cands = {}
    local user_cands = {}
    local other_cands = {}
    local user_count = 0
    local scanned = 0
    local max_end = nil
    local first_text_len = nil

    for cand in input:iter() do
        scanned = scanned + 1

        -- 权重大于等于 90 的一般是自定义短语（custom_phrase，如 initial_quality: 99）或强制置顶
        -- 这类内容应始终保持最前，不被动态调整
        if cand.quality and cand.quality >= 90 then
            table.insert(high_quality_cands, cand)
        else
            -- 记录首个常规候选所覆盖的输入编码跨度与文字长度
            if max_end == nil then
                max_end = cand._end or 0
                first_text_len = utf8.len(cand.text) or 0
            end

            -- 只有当用户记忆词覆盖了相同的输入编码长度（即完整匹配当前整串拼音），
            -- 且字数不小于当前首选候选词时，才允许置顶；
            -- 严禁将只匹配前缀单字的短词（如输入 chuchangdongli 时的单字“出”）置顶抢占长词位置！
            local cand_end = cand._end or 0
            local cand_len = utf8.len(cand.text) or 0
            local is_full_match = (cand_end >= max_end) and (cand_len >= first_text_len)

            if is_user_cand[cand.type] and is_full_match and user_count < M.max_count then
                table.insert(user_cands, cand)
                user_count = user_count + 1
            else
                table.insert(other_cands, cand)
            end
        end

        if user_count >= M.max_count or scanned >= M.scan_limit then
            break
        end
    end

    -- 1. 输出超高权重候选（如 custom_phrase 自定义短语）
    for _, cand in ipairs(high_quality_cands) do
        yield(cand)
    end

    -- 2. 输出提升到前排的用户记忆词
    for _, cand in ipairs(user_cands) do
        yield(cand)
    end

    -- 3. 输出前瞻窗口内暂存的普通词
    for _, cand in ipairs(other_cands) do
        yield(cand)
    end

    -- 4. 输出剩余流中的所有候选
    for cand in input:iter() do
        yield(cand)
    end
end

return M
