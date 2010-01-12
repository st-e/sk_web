// How to identify a person (first one wins):
//   - club_id_old (with club) - only if unique to prevent damage
//   - club_id (with club) - only if unique to prevent damage
//   - first/last name (with club) - only if unique
// Return the ID of the person, or 0 if it doesn't exist, and a list of errors
//

identify_person
{
	if (club_id_old given)
	{
		// Find people with this club ID
		// Exactly 1 => found it
		// None => not found error
		// Multiple => club ID not unique
	}
	else if (club_id_given)
	{
		// Find people with this club ID
		// Exactly 1 => found it
		// None => select by name (or: new person?)
		// Multiple => club ID not unique
	}
	else
	{
		// Select by name
	}

	// No club id or old club ID given => person w/o club id or new person
	// Find people with this name and the correct club; club_id must also be
	//   empty (to remove a club ID, we have to select the person by old club
	//   ID)
	// None
	//   new person
	// Multiple people
	//   non-unique error
	//
	// Additional feature: when there are people with the same name without a
	// club (or in a different club), suggest :merge
}

csv_to_persons(csv, club)
{
	// Parse the header row
	// Make sure the required fields are present (last name, first name, club
	// id (?)), if not => error message + back link/button

	// Determine the column indices of the columns (above + club_id,
	// club_id_old, comments)

	// Parse the rest, create people (with the given club)
}

