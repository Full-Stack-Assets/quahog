using UnrealBuildTool;
using System.Collections.Generic;

public class MountHopeEditorTarget : TargetRules
{
    public MountHopeEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.AddRange(new string[] { "MountHope" });
    }
}
