sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"com/sparebridge/breakdownui/test/integration/pages/BreakdownRequestsList",
	"com/sparebridge/breakdownui/test/integration/pages/BreakdownRequestsObjectPage"
], function (JourneyRunner, BreakdownRequestsList, BreakdownRequestsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('com/sparebridge/breakdownui') + '/test/flp.html#app-preview',
        pages: {
			onTheBreakdownRequestsList: BreakdownRequestsList,
			onTheBreakdownRequestsObjectPage: BreakdownRequestsObjectPage
        },
        async: true
    });

    return runner;
});

