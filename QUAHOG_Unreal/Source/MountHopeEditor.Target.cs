using UnrealBuildTool;
using System.Collections.Generic;

public class MountHopeEditorTarget : TargetRules
{
    public MountHopeEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
        ExtraModuleNames.AddRange(new string[] { "MountHope" });
    }
}
