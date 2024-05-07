const templateDefinition = {
    entityName: undefined,
    indefiniteArticle: undefined,
}

const template = `using System;
using Jfw.Core.Enums;
using Jfw.Helpers;

namespace Jfw.Core.EntityClasses
{
    public partial class C{{entityName}}
    {
        /// <summary>
        /// Gets a dummy object.
        /// </summary>
        /// <returns>The dummy instance for sanity testing.</returns>
        internal static C{{entityName}} GetDummy()
        {
            return new C{{entityName}}();
        }

        /// <summary>
        /// Tries to modify the testing object.
        /// </summary>
        /// <param name="{{indefiniteArticle}}{{entityName}}">The testing object.</param>
        internal static void TryModify(ref C{{entityName}} {{indefiniteArticle}}{{entityName}})
        {
        }

        /// <summary>
        /// Runs a simple unit-test on User.
        /// </summary>
        public static void UnitTest()
        {
            string className = typeof(C{{entityName}}).Name;
            _logger.Information("--- {ClassName} List ---", className);
            _logger.Information("Call static method List() from {ClassName}", className);
            var anEntityList = List();
            _logger.Debug("{EntityList}", DebugHelper.SerializeObject(anEntityList));

            _logger.Information("--- {ClassName} Add ---", className);
            _logger.Information("Initialize a test instance");
            var newInstance = GetDummy();
            _logger.Debug("Default instance:");
            _logger.Debug("{EntityClassInstance}", DebugHelper.SerializeObject(newInstance));
            _logger.Information("Call static method Add() from {ClassName}", className);
            var newCreatedInstance = Add(newInstance);
            _logger.Debug("The new created instance:");
            _logger.Debug("{EntityClassInstance}", DebugHelper.SerializeObject(newCreatedInstance));

            _logger.Information("--- {ClassName} Get ---", className);
            _logger.Debug("Call static method Get() from {ClassName} with Id [{Id}]", className, newCreatedInstance.Id);
            var instanceFromDb = Get(newCreatedInstance.Id);
            _logger.Debug("The instance from db:");
            _logger.Debug("{EntityClassInstance}", DebugHelper.SerializeObject(instanceFromDb));

            _logger.Information("--- {ClassName} Update ---", className);
            _logger.Debug("Try to update the instance from db with some modifications");
            TryModify(ref instanceFromDb);
            var updatedInstance = Update(instanceFromDb);
            _logger.Debug("The updated instance:");
            _logger.Debug("{EntityClassInstance}", DebugHelper.SerializeObject(updatedInstance));

            _logger.Information("--- {ClassName} Delete ---", className);
            _logger.Debug("Call static method Delete() from {ClassName} with Id [{Id}]", className, updatedInstance.Id);
            var affectedRows = Delete(updatedInstance.Id);
            _logger.Debug("The affected rows: {AffectedRows}", affectedRows);
        }
    }
}
`;

module.exports = { template, templateDefinition };
