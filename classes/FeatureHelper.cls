public without sharing class FeatureHelper {
    
    public boolean branchMgmtEnabled {get;set;}
    public boolean complianceHubEnabled {get;set;}
    
    public static boolean isFeatureEnabled(String feature){
        LicenseManagerController lmc = new LicenseManagerController();
        Boolean res = true;

        if (feature == 'Compliance Hub') {
            res = lmc.cchLicensesAvailable >0;
        }
        else if (feature == 'Selenium Testing') {
            res = lmc.cstLicensesAvailable > 0;
        }
        else if (feature == 'Branch Management') {
            res = lmc.cbmBranchesAvailable > 0;
        }
        else {
            res = lmc.copadoLicensesAvailable >0;
        }
        system.debug('***** Feature: '+ feature + ' = ' + res);
        return res;
    }
    public static boolean isBranchMgmtEnabled(){
        return featureHelper.isFeatureEnabled('Branch Management');
    }
    public static boolean isComplianceHubEnabled(){
        return featureHelper.isFeatureEnabled('Compliance Hub');
    }

    public static boolean isChangeChangeManagementEnabled(){
        return featureHelper.isFeatureEnabled('Change Management');
    }
    
    //Constructors
    private void constructor(){
        branchMgmtEnabled = isBranchMgmtEnabled();
        complianceHubEnabled = isComplianceHubEnabled();
    }
    public FeatureHelper(){
        constructor();
    }
    public FeatureHelper(ApexPages.StandardController stdController){
        constructor();
    }
}