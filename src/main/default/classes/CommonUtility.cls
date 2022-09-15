/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

public with sharing class CommonUtility {
    public static Boolean isMoreThanXWeeksAgo(Date referenceDate, Integer numberOfWeeks) {
        return referenceDate.daysBetween(System.today()) > numberOfWeeks * 7;
    }
}