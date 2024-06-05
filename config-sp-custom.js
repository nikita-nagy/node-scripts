const { tableSchema } = require("./config");

const spConfig = {
  Brand: {
    alias: {
      Brand: "B",
      BrandEmail: "BE",
      BrandSetting: "BS",
      BrandProfile: "BP",
    },
    childTables: ["BrandEmail", "BrandSetting", "BrandProfile"],
    customParameters: {
      Brand_URL: {
        name: "Brand_URL",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Gets ID from Brand URL if ID is not provided.
\tIF @Brand_URL IS NOT NULL AND @Brand_URL <> '' AND @ID IS NULL
\tBEGIN
\t\tSET @ID = [${tableSchema}].[fn_GetBrandID](@Brand_URL)
\tEND
  `,
        // For C# filter.
        propertyName: "BrandUrl",
        propertyType: "string",
      },
    },
  },
  Device: {
    alias: {
      Device: "D",
      DeviceProfile: "DP",
      DeviceSetting: "DS",
    },
    childTables: ["DeviceProfile", "DeviceSetting"],
    customParameters: {
      brandId: {
        name: "Brand_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Brand_ID if Brand_ID is not null.
\tIF @Brand_ID IS NOT NULL AND @Brand_ID <> ''
\tBEGIN
\t\tSET @whereClause = CONCAT(@whereClause, ' AND [User_ID] IN (SELECT [ID] FROM [${tableSchema}].[User] WHERE [Brand_ID] IN (SELECT tvalue FROM [${tableSchema}].[fn_Split](''', @Brand_ID, ''', DEFAULT))) ')
\tEND`,
        // For C# filter.
        propertyName: "BrandId",
        propertyType: "string",
      },
    },
  },
  User: {
    alias: {
      User: "U",
      UserProfile: "UP",
      UserSetting: "US",
    },
    precondition: "",
    childTables: ["UserProfile", "UserSetting"],
    customParameters: {
      brandUrl: {
        name: "Brand_URL",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Gets Brand_ID from Brand URL if Brand_ID is not provided.
\tIF @Brand_URL IS NOT NULL AND @Brand_URL <> '' AND @Brand_ID IS NULL
\tBEGIN
\t\tSET @Brand_ID = [${tableSchema}].[fn_GetBrandID](@Brand_URL)
\tEND
  `,
        // For C# filter.
        propertyName: "BrandUrl",
        propertyType: "string",
      },
      externalProviderId: {
        name: "External_Provider_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by External_Provider_ID if External_Provider_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteriaWithTableAlias]('User_ID', 'ExternalAuthenticationProviderUser', 'External_Authentication_Provider_ID', @External_Provider_ID, 'U'), @newline)
`,
        // For C# filter.
        propertyName: "ExternalProviderId",
        propertyType: "string",
      },
      externalUserId: {
        name: "External_User_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by External_User_ID if External_User_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteriaWithTableAlias]('User_ID', 'ExternalAuthenticationProviderUser', 'External_Authentication_User_ID', @External_User_ID, 'U'), @newline)
`,
        // For C# filter.
        propertyName: "ExternalUserId",
        propertyType: "string",
      },
      roleId: {
        name: "Role_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Role_ID if Role_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteriaWithTableAlias]('User_ID', 'UserRole', 'Role_ID', @Role_ID, 'U'), @newline)
  `,
        // For C# filter.
        propertyName: "RoleId",
        propertyType: "string",
      },
      sameOrganizationWithUserId: {
        // SELECT * FROM [JFW].[User] U WHERE U.[ID] IN (
        //   SELECT DISTINCT [User_ID]
        //   FROM [JFW].[OrganizationUser] OU
        //   WHERE OU.[Organization_ID] IN (SELECT O.[ID]
        //     FROM [JFW].[Organization] O
        //     -- Need to join with the [JFW].[OrganizationUser] table to get the organization ID.
        //     JOIN [JFW].[OrganizationUser] OU ON O.[ID] = OU.[Organization_ID]
        //     WHERE OU.[Status] = 1 AND OU.[User_ID] = 2))
        name: "Same_Organization_With_User_ID",
        type: "BIGINT",
        filterCriteriaContent: `\t-- Filters by Same_Organization_With_User_ID if Same_Organization_With_User_ID is not null.
\tIF @Same_Organization_With_User_ID IS NOT NULL AND @Same_Organization_With_User_ID <> 0
\tBEGIN
\tSET @whereClause = CONCAT(@whereClause, ' AND U.[ID] IN (SELECT DISTINCT OU.[User_ID] FROM [${tableSchema}].[OrganizationUser] OU WHERE OU.[Organization_ID] IN (SELECT O.[ID] FROM [${tableSchema}].[Organization] O JOIN [${tableSchema}].[OrganizationUser] OU ON O.[ID] = OU.[Organization_ID] WHERE OU.[Status] = 1 AND OU.[User_ID] = ', @Same_Organization_With_User_ID, ')) ', @newline)
\tEND`,
        // For C# filter.
        propertyName: "SameOrganizationWithUserId",
        propertyType: "long?",
      },
    },
  },
  Feature: {
    alias: {
      Feature: "F",
    },
    childTables: [],
    customParameters: {
      packageId: {
        name: "Package_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Package_ID if Package_ID is not null.
  \tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('Feature_ID', 'PackageFeature', 'Package_ID', @Package_ID), @newline)
  `,
        // For C# filter.
        propertyName: "PackageId",
        propertyType: "string",
      },
    },
  },
  Package: {
    alias: {
      Package: "P",
    },
    childTables: [],
    customParameters: {
      priceId: {
        name: "Price_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Price_ID if Price_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('Package_ID', 'Price', 'ID', @Price_ID), @newline)
  `,
        // For C# filter.
        propertyName: "PriceId",
        propertyType: "string",
      },
    },
  },
  Role: {
    alias: {
      Role: "R",
    },
    childTables: [],
    customParameters: {
      userId: {
        name: "User_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by User_ID if User_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('Role_ID', 'UserRole', 'User_ID', @User_ID), @newline)
`,
        // For C# filter.
        propertyName: "UserId",
        propertyType: "string",
      },
      permissionId: {
        name: "Permission_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Permission_ID if Permission_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('Role_ID', 'RolePermission', 'Permission_ID', @Permission_ID), @newline)
`,
        // For C# filter.
        propertyName: "PermissionId",
        propertyType: "string",
      },
    },
  },
  Permission: {
    alias: {
      Permission: "P",
    },
    childTables: [],
    customParameters: {
      roleId: {
        name: "Role_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Role_ID if Role_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('Permission_ID', 'RolePermission', 'Role_ID', @Role_ID), @newline)
  `,
        // For C# filter.
        propertyName: "RoleId",
        propertyType: "string",
      },
    },
  },
  Coupon: {
    alias: {
      Coupon: "C",
    },
    childTables: [],
    customParameters: {
      userId: {
        name: "User_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by User_ID if User_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('Coupon_ID', 'CouponUser', 'User_ID', @User_ID), @newline)
  `,
        // For C# filter.
        propertyName: "UserId",
        propertyType: "string",
      },
    },
  },
  ExternalProvider: {
    alias: {
      ExternalProvider: "EP",
    },
    childTables: [],
    customParameters: {
      userId: {
        name: "User_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by User_ID if User_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('ExternalProvider_ID', 'UserExternalProvider', 'User_ID', @User_ID), @newline)
  `,
        // For C# filter.
        propertyName: "UserId",
        propertyType: "string",
      },
    },
  },
  Issue: {
    alias: {
      Issue: "I",
    },
    childTables: [],
    customParameters: {
      onlyParent: {
        name: "Only_Parent",
        type: "BIT",
        filterCriteriaContent: `\t-- [SP Custom] Filters by Only_Parent if Only_Parent is not null.
\tIF (@Only_Parent IS NULL OR @Only_Parent = 1) AND @Parent_ID IS NULL
\tBEGIN
\tSET @whereClause = CONCAT(@whereClause, ' AND [Parent_ID] IS NULL ', @newline)
\tEND
`,
        // For C# filter.
        propertyName: "OnlyParent",
        propertyType: "bool?",
      },
      userId: {
        name: "User_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- [SP Custom] Filters by User_ID if User_ID is not null. We search on Modified_By and Created_By for User_ID.
\tIF @User_ID IS NOT NULL AND @User_ID <> ''
\tBEGIN
\tSET @whereClause = CONCAT(@whereClause, ' AND [Created_By] IN (SELECT tvalue FROM [JFW].[fn_Split](''', @User_ID, ''', DEFAULT)) ', @newline)
\tEND
`,
        // For C# filter.
        propertyName: "UserId",
        propertyType: "string",
      },
    },
  },
  Organization: {
    alias: {
      Organization: "O",
    },
    childTables: [],
    customParameters: {
      userId: {
        name: "User_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by User_ID if User_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [${tableSchema}].[fn_GetForeignKeyFilterCriteria]('Organization_ID', 'OrganizationUser', 'User_ID', @User_ID), @newline)
`,
        // For C# filter.
        propertyName: "UserId",
        propertyType: "string",
      },
    },
  },
};

const spChildTables = {
  BrandEmail: {
    suffix: "Email",
    ignoredColumns: [
      "Brand_ID",
      "Modified_By",
      "Modified_Date",
      "Created_By",
      "Created_Date",
    ],
  },
  BrandSetting: {
    suffix: "Setting",
    ignoredColumns: [
      "Brand_ID",
      "Modified_By",
      "Modified_Date",
      "Created_By",
      "Created_Date",
    ],
  },
  BrandProfile: {
    suffix: "Profile",
    ignoredColumns: [
      "Brand_ID",
      "Modified_By",
      "Modified_Date",
      "Created_By",
      "Created_Date",
    ],
  },
  DeviceProfile: {
    suffix: "Profile",
    ignoredColumns: [
      "Device_ID",
      "Modified_By",
      "Modified_Date",
      "Created_By",
      "Created_Date",
    ],
  },
  DeviceSetting: {
    suffix: "Setting",
    ignoredColumns: [
      "Device_ID",
      "Modified_By",
      "Modified_Date",
      "Created_By",
      "Created_Date",
    ],
  },
  UserProfile: {
    suffix: "Profile",
    ignoredColumns: [
      "User_ID",
      "Modified_By",
      "Modified_Date",
      "Created_By",
      "Created_Date",
    ],
  },
  UserSetting: {
    suffix: "Setting",
    ignoredColumns: [
      "User_ID",
      "Modified_By",
      "Modified_Date",
      "Created_By",
      "Created_Date",
    ],
  },
};

module.exports = {
  spConfig,
  spChildTables,
};
