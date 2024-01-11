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
        no_data = 'No data',
        job = 'Job',
        job_grade = 'Grade',
        funds_in_cash = 'Funds in cash',
        funds_in_bank = 'Funds in bank',
        citizenid = 'Citizen ID',
        serverid = 'Server ID',
        view_stats = 'View stats',

    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
