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
\t\tSET @whereClause = CONCAT(@whereClause, ' AND [User_ID] IN (SELECT [ID] FROM [JFW].[User] WHERE [Brand_ID] IN (SELECT tvalue FROM [JFW].[fn_Split](''', @Brand_ID, ''', DEFAULT))) ')
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
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteriaWithTableAlias]('User_ID', 'ExternalAuthenticationProviderUser', 'External_Authentication_Provider_ID', @External_Provider_ID, 'U'), @newline)
`,
        // For C# filter.
        propertyName: "ExternalProviderId",
        propertyType: "string",
      },
      externalUserId: {
        name: "External_User_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by External_User_ID if External_User_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteriaWithTableAlias]('User_ID', 'ExternalAuthenticationProviderUser', 'External_Authentication_User_ID', @External_User_ID, 'U'), @newline)
`,
        // For C# filter.
        propertyName: "ExternalUserId",
        propertyType: "string",
      },
      roleId: {
        name: "Role_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Role_ID if Role_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteriaWithTableAlias]('User_ID', 'UserRole', 'Role_ID', @Role_ID, 'U'), @newline)
  `,
        // For C# filter.
        propertyName: "RoleId",
        propertyType: "string",
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
  \tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteria]('Feature_ID', 'PackageFeature', 'Package_ID', @Package_ID), @newline)
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
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteria]('Package_ID', 'Price', 'ID', @Price_ID), @newline)
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
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteria]('Role_ID', 'UserRole', 'User_ID', @User_ID), @newline)
`,
        // For C# filter.
        propertyName: "UserId",
        propertyType: "string",
      },
      permissionId: {
        name: "Permission_ID",
        type: "VARCHAR(MAX)",
        filterCriteriaContent: `\t-- Filters by Permission_ID if Permission_ID is not null.
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteria]('Role_ID', 'RolePermission', 'Permission_ID', @Permission_ID), @newline)
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
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteria]('Permission_ID', 'RolePermission', 'Role_ID', @Role_ID), @newline)
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
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteria]('Coupon_ID', 'CouponUser', 'User_ID', @User_ID), @newline)
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
\tSET @whereClause = CONCAT(@whereClause, [JFW].[fn_GetForeignKeyFilterCriteria]('ExternalProvider_ID', 'UserExternalProvider', 'User_ID', @User_ID), @newline)
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
