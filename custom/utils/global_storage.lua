-- ~/.config/awesome/custom/utils/global_storage.lua
local GlobalStorage = {}

-- Хранилище данных и слушателей
local storage = {}
local listeners = {}

-- Установка значения
function GlobalStorage.set(key, value)
    local old_value = storage[key]
    storage[key] = value

    -- Уведомляем слушателей если значение изменилось
    if old_value ~= value and listeners[key] then
        for _, callback in ipairs(listeners[key]) do
            callback(value, old_value)
        end
    end
end

-- Получение значения
function GlobalStorage.get(key)
    return storage[key]
end

-- Подписка на изменения
function GlobalStorage.listen(key, callback)
    if not listeners[key] then
        listeners[key] = {}
    end
    table.insert(listeners[key], callback)
end

-- Отписка от изменений
function GlobalStorage.unlisten(key, callback)
    if listeners[key] then
        for i, cb in ipairs(listeners[key]) do
            if cb == callback then
                table.remove(listeners[key], i)
                break
            end
        end
    end
end

return GlobalStorage