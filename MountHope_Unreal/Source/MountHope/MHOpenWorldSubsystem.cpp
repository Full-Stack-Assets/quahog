#include "MHOpenWorldSubsystem.h"

FMHMapSourceProfile UMHOpenWorldSubsystem::GetDefaultMapSource() const
{
    FMHMapSourceProfile Profile;
    Profile.Name = TEXT("SouthCoastOSM");
    Profile.SourcePath = TEXT("../quahog-project-files/mapdata/southcoast-roads.json");
    Profile.MetersToUnrealUnits = 100.0f;
    Profile.bAllowFictionalizedEdits = true;
    return Profile;
}
