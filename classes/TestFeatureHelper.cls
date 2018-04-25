@isTest
public class TestFeatureHelper {
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(1,1,1,1,1,1);
    }
    static testMethod void isChangeManagementEnabled(){
        system.assertEquals(true,FeatureHelper.isChangeChangeManagementEnabled());
    }
    static testMethod void isComplianceHubEnabled(){
        system.assertEquals(true,FeatureHelper.isComplianceHubEnabled());
    }
    static testMethod void isSeleniumEnabled(){
        system.assertEquals(true,FeatureHelper.isFeatureEnabled('Selenium Testing'));
    }
    static testMethod void isCopadoEnabled(){
        system.assertEquals(true,FeatureHelper.isFeatureEnabled('Git Backup'));
        system.assertEquals(true,FeatureHelper.isFeatureEnabled('Git MetaData'));
    }
}