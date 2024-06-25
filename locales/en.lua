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
        outlawstatus = 'Outlaw Status',
        job = 'Job',
        job_grade = 'Job Grade',
        funds_in_cash = 'Funds in cash',
        funds_in_bank = 'Funds in St.Denis bank',
        funds_in_armbank = 'Funds in Armadillo bank',
        funds_in_rhobank = 'Funds in Rhodes bank',
        funds_in_blkbank = 'Funds in Blackwater bank',
        funds_in_valbank = 'Funds in Valentine bank',
        citizenid = 'Citizen ID',
        serverid = 'Server ID',
        view_stats = 'View stats',

    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
