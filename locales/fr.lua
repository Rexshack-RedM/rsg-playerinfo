local Translations = {
    error = {
        error_var = 'Example Text',
    },
    success = {
        success_var = 'Example Text',
    },
    primary = {
        primary_var = 'Example Text',
    },
    menu = {
        no_data = 'Aucune donnée',
        outlawstatus = 'Outlaw Status',
        job = 'Job',
        job_grade = 'Grade',
        funds_in_cash = 'Fonds en cash',
        funds_in_bank = 'Fonds en banque',
        citizenid = 'Numéro de citoyen',
        serverid = 'ID du serveur',
        view_stats = 'Voir mes informations',
    },
}

if GetConvar('rsg_locale', 'en') == 'fr' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end