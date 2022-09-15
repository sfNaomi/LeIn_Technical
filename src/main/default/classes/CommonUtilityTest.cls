/**
 * Created by magdalena.stanciu on 14.09.2022.
 */

@IsTest
public with sharing class CommonUtilityTest {
    @IsTest
    public static void testIsMoreThanXWeeksAgo() {
        System.assertEquals(FALSE, CommonUtility.isMoreThanXWeeksAgo(System.today(), 1));
        System.assertEquals(TRUE, CommonUtility.isMoreThanXWeeksAgo(System.today().addDays(-8), 1));
    }
}