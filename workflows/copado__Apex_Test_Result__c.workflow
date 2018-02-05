<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Apex_Test_Results_Summary</fullName>
        <description>Apex Test Results Summary</description>
        <protected>false</protected>
        <recipients>
            <recipient>pfernandez@copa.do.demo</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>copado__Copado_Deployer/copado__Apex_Test_Result_Summary</template>
    </alerts>
    <rules>
        <fullName>Apex Test Results Summary</fullName>
        <active>true</active>
        <formula>TRUE</formula>
        <triggerType>onCreateOnly</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Apex_Test_Results_Summary</name>
                <type>Alert</type>
            </actions>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
