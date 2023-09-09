local Translations = {
error = {
    error_var = 'Texto de Exemplo',
},
success = {
    success_var = 'Texto de Exemplo',
},
primary = {
    primary_var = 'Texto de Exemplo',
},
menu = {
    menu_var = 'Texto de Exemplo',
},
}

if GetConvar('rsg_locale', 'en') == 'pt-br' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
