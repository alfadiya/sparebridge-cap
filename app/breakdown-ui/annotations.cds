using SpareBridgeService as service from '../../srv/sparebridge-service';

annotate service.BreakdownRequests with @(
    Capabilities.InsertRestrictions : { Insertable : true },
    Capabilities.DeleteRestrictions : { Deletable  : false },
    UI.UpdateHidden                 : true,

    // --- Page title shown on the Object Page (detail screen) ---
    UI.HeaderInfo : {
        TypeName       : 'Breakdown Request',
        TypeNamePlural : 'Breakdown Requests',
        Title          : { Value : material },
        Description    : { Value : plant.name }
    },

    // --- Buttons shown on the DETAIL page toolbar ---
    UI.Identification : [
        {
            $Type  : 'UI.DataFieldForAction',
            Label  : 'Find Matches',
            Action : 'SpareBridgeService.findMatches',
        },
    ],

    // --- Color coding for breakdown status ---
    UI.DataPoint #StatusDP : {
        Value       : status,
        Criticality : statusCriticality
    },

    // --- Columns shown in the LIST page table ---
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Plant',
            Value : plant.name,       // shows "IOCL Panipat Refinery" instead of "P001"
        },
        {
            $Type : 'UI.DataField',
            Label : 'Material',
            Value : material,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Quantity Needed',
            Value : quantity,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Urgency (1-5)',
            Value : urgency,
        },
        {
            $Type  : 'UI.DataFieldForAnnotation',
            Label  : 'Status',
            Target : '@UI.DataPoint#StatusDP',
        },
        {
            $Type : 'UI.DataField',
            Label : 'Fulfilled',
            Value : fulfilledQty,
        },
    ],

    // --- Fields shown on the DETAIL page (Object Page) ---
    UI.FieldGroup #GeneralInfo : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Plant',
                Value : plant_ID,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Material',
                Value : material,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Quantity Needed',
                Value : quantity,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Urgency (1=Low, 5=Critical)',
                Value : urgency,
            },
            {
                $Type             : 'UI.DataField',
                Label             : 'Status',
                Value             : status,
                ![@UI.Hidden]     : { $edmJson : { $Not : { $Path : 'IsActiveEntity' } } }
            },
            {
                $Type             : 'UI.DataField',
                Label             : 'Fulfilled Quantity',
                Value             : fulfilledQty,
                ![@UI.Hidden]     : { $edmJson : { $Not : { $Path : 'IsActiveEntity' } } }
            },
            {
                $Type             : 'UI.DataField',
                Label             : 'Matches Last Found',
                Value             : matchedAt,
                ![@UI.Hidden]     : { $edmJson : { $Not : { $Path : 'IsActiveEntity' } } }
            },
        ],
    },

    // --- Sections shown on the DETAIL page ---
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneralInfo',
            Label : 'Breakdown Details',
            Target : '@UI.FieldGroup#GeneralInfo',
        },
        {
            $Type         : 'UI.ReferenceFacet',
            ID            : 'MatchResults',
            Label         : 'Match Results',
            Target        : 'matchResults/@UI.PresentationVariant',
            ![@UI.Hidden] : { $edmJson : { $Not : { $Path : 'IsActiveEntity' } } }
        },
        {
            $Type         : 'UI.ReferenceFacet',
            ID            : 'TransferOrders',
            Label         : 'Stock Transfer Orders (STO)',
            Target        : 'transferOrders/@UI.PresentationVariant',
            ![@UI.Hidden] : { $edmJson : { $Not : { $Path : 'IsActiveEntity' } } }
        },
    ],
);

// --- Auto-refresh Match Results after findMatches runs ---
annotate service.BreakdownRequests actions {
    findMatches @(
        Common.SideEffects : {
            TargetEntities : [ $self, matchResults ]
        }
    )
};

// --- Auto-refresh Breakdown Details after approveMatch runs ---
annotate service.MatchResults actions {
    approveMatch @(
        Common.SideEffects : {
            TargetEntities : [ request ]
        }
    )
};

// --- Color coding for match result status ---
annotate service.MatchResults with @(
    UI.DataPoint #MatchStatusDP : {
        Value       : status,
        Criticality : statusCriticality
    }
);

// --- Disable Approve button when match is already approved ---
annotate service.MatchResults with actions {
    approveMatch @(Core.OperationAvailable : canApprove)
};

// --- Match Results table columns + Approve button ---
annotate service.MatchResults with @(
    UI.PresentationVariant : {
        SortOrder      : [{
            Property   : rank,
            Descending : false
        }],
        Visualizations : [ '@UI.LineItem' ]
    },
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Rank',
            Value : rank,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Source Plant',
            Value : sourcePlant.name,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Distance (km)',
            Value : distanceKm,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Transferable Qty',
            Value : transferableQty,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Fulfils?',
            Value : canFullyFulfil,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Est. Cost (₹10/km)',
            Value : estimatedCost,
        },
        {
            $Type  : 'UI.DataFieldForAnnotation',
            Label  : 'Match Status',
            Target : '@UI.DataPoint#MatchStatusDP',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Label  : 'Approve',
            Action : 'SpareBridgeService.approveMatch',
            Inline : true,
        },
    ],
);

// --- Disable STO buttons based on status ---
annotate service.TransferOrders with actions {
    markInTransit @(Core.OperationAvailable : canMarkShipped);
    markDelivered @(Core.OperationAvailable : canMarkDelivered);
};

// --- Stock Transfer Orders (STO) section ---
annotate service.TransferOrders with @(
    UI.PresentationVariant : {
        SortOrder      : [{ Property: createdAt, Descending: false }],
        Visualizations : [ '@UI.LineItem' ]
    },
    UI.DataPoint #STOStatus : {
        Value       : status,
        Criticality : statusCriticality
    },
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'From Plant',
            Value : match.sourcePlant.name,
        },
        {
            $Type : 'UI.DataField',
            Label : 'To Plant',
            Value : toPlant.name,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Material',
            Value : match.request.material,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Quantity',
            Value : quantity,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Created On',
            Value : createdAt,
        },
        {
            $Type  : 'UI.DataFieldForAnnotation',
            Label  : 'Status',
            Target : '@UI.DataPoint#STOStatus',
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Label  : 'Mark Shipped',
            Action : 'SpareBridgeService.markInTransit',
            Inline : true,
        },
        {
            $Type  : 'UI.DataFieldForAction',
            Label  : 'Mark Delivered',
            Action : 'SpareBridgeService.markDelivered',
            Inline : true,
        },
    ],
);

// --- Required fields for create form ---
annotate service.BreakdownRequests with {
    plant    @mandatory;
    material @mandatory;
    quantity @mandatory;
    urgency  @mandatory;
};

// --- Material dropdown ---
annotate service.BreakdownRequests with {
    material @(
        Common.ValueListWithFixedValues : true,
        Common.ValueList : {
            CollectionPath  : 'Materials',
            SearchSupported : true,
            Parameters      : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : material,
                    ValueListProperty : 'code',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'description',
                },
            ],
        }
    )
};

// --- Plant dropdown for create/edit form ---
annotate service.BreakdownRequests with {
    plant @(
        Common.Text            : plant.name,
        Common.TextArrangement : #TextOnly,
        Common.ValueList : {
            CollectionPath  : 'Plants',
            SearchSupported : true,
            Parameters      : [
                {
                    $Type             : 'Common.ValueListParameterInOut',
                    LocalDataProperty : plant_ID,
                    ValueListProperty : 'ID',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'name',
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'city',
                },
            ],
        }
    )
};
