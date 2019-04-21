/**
 * Created by Kairat on 03-Nov-16.
 */

// register _moneyToWordsRU function for stimulsoft
function _moneyToWordsRU(summ){
    var moneyToStr = new MoneyToStr("KGS", "RUS");
    return moneyToStr.convertValue(summ);
}
Stimulsoft.Report.Dictionary.StiFunctions.addFunction(
    "Strings", 		// category
    "", 			// groupFuncName
    "moneyToWordsRU", // funcName
    "", 			// description
    "", 			// typeOfFunc
    String, 		// returnType
    "", 			// returnDescription
    [String], 		// argTypes[]
    [""], 			// argNames[]
    [""], 			// argDescription[]
    _moneyToWordsRU 	// Function
);


function _isDateString(date_string) {
    if (angular.isUndefined(date_string) || date_string == null || date_string == '') return false;
    return /^\d{4}(?:-|\.)\d{2}(?:-|\.)\d{2}(?:[T\s]\d{2}:\d{2}(?::\d{2}(?:\.\d{3})?)?(?:(?:(?:\+|-)\d{2}(?::?\d{2})?)|Z)?)?$/.test(date_string)
}
Stimulsoft.Report.Dictionary.StiFunctions.addFunction(
    "Strings",
    "StrDate",
    "isDateString",
    "",
    "",
    Boolean,
    "",
    [String],
    ["DateString"],
    [""],
    _isDateString
);


function _calendar(date_string, only_date) {
    if (angular.isUndefined(date_string) || date_string == null || date_string == '') return date_string;
    if (!_isDateString(date_string)) return date_string;
    if (only_date) {
        try {
            return moment(date_string).calendar(moment(), {
                sameDay: '[Сегодня]',
                nextDay: '[Завтра]',
                nextWeek: '[В] dddd',
                lastDay: '[Вчера]',
                lastWeek: function (now) {
                    var dow = this.format('E') * 1;
                    var day_of_week = moment(this).calendar(now, {lastWeek: '[В] dddd'});
                    day_of_week = day_of_week.replace('В ', '');
                    if ([1, 2, 4].indexOf(dow) > -1) {
                        return 'В прошлый ' + day_of_week;
                    }
                    if ([3, 5, 6].indexOf(dow) > -1) {
                        return 'В прошлую ' + day_of_week;
                    }
                    if ([7].indexOf(dow) > -1) {
                        return 'В прошлое ' + day_of_week;
                    }
                    return this.format('Do MMM YYYY');
                },
                sameElse: 'Do MMM YYYY'
            });
        } catch(e) {
            console.warn(e);
        }
    }
    return moment(date_string).calendar();
}
Stimulsoft.Report.Dictionary.StiFunctions.addFunction(
    "Strings",
    "StrDate",
    "calendar",
    "",
    "",
    String,
    "",
    [String, Boolean],
    ["DateString", 'OnlyDate'],
    [""],
    _calendar
);


function _fromNow(date_string) {
    if (angular.isUndefined(date_string) || date_string == null || date_string == '') return date_string;
    return moment(date_string).fromNow()
}
Stimulsoft.Report.Dictionary.StiFunctions.addFunction(
    "Strings",
    "StrDate",
    "fromNow",
    "",
    "",
    String,
    "",
    [String],
    ["DateString"],
    [""],
    _fromNow
);


function _strDate2Format(date_string, date_format) {
    if (angular.isUndefined(date_string) || date_string == null || date_string == '') return date_string;
    if (date_format) try {
        return moment(date_string).format(date_format);
    } catch(e) {
        console.warn(e);
    }
    return moment(date_string).format();
}
Stimulsoft.Report.Dictionary.StiFunctions.addFunction(
    "Strings",
    "StrDate",
    "strDate2Format",
    "",
    "",
    String,
    "",
    [String, String],
    ["DateString","Format"],
    [""],
    _strDate2Format
);


function _str2num(numebr_string) {
    if (angular.isUndefined(date_string) || date_string == null || date_string == '') return 0;
    try {
        return numebr_string * 1;
    } catch(e) {
        console.warn(e);
    }
    return 0;
}
Stimulsoft.Report.Dictionary.StiFunctions.addFunction(
    "Numbers",
    "",
    "str2num",
    "",
    "",
    Number,
    "",
    [String],
    ["NumberString"],
    [""],
    _str2num
);


function _hasColumn(row_object, column_name) {
    console.log(row_oject, column_name);
    if (angular.isUndefined(row_object) || row_object == null || row_object == '') return false;
    try {
        return !!row_object[column_name];
    } catch(e) {
        console.warn(e);
    }
    return false;
}
Stimulsoft.Report.Dictionary.StiFunctions.addFunction(
    "Numbers",
    "",
    "HasColumn",
    "",
    "",
    Boolean,
    "",
    [Object, String],
    ["RowObject", 'ColumnName'],
    [""],
    _hasColumn
);


