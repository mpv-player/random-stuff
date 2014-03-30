© 2006 Microsoft Corporation. The profile is provided for use as a test file and “AS IS” without warranty of any kind.  The entire risk as to the results and performance of the profile is assumed by user.  Microsoft disclaims all warranties, either express, implied or statutory, including but not limited to, the implied warranties of merchantability and fitness for a particular purpose, and warranties of title and noninfringement, with respect to the profile. All other rights reserved.


This profile utilization test sample consists of:

BGR-Wcs-RBG-Icc-Test.icc

	This is a specially prepared ICC display profile that contains a WCS profile in an 'MS10' tag.

	The ICC profile has the blue and green channels swapped. An RGB image with its channels swapped to RBG will render
        "naturally" with this ICC profile used as source profile. An unswapped RGB image will render through this profile
        so that blue content will appear green, and green content will appear blue.

	The WCS device model profile contained within a 'MS00' tag in the ICC profile has its red and blue channels swapped.
        An RGB image with its channels swapped to BGR will render "naturally" through this WCS profile. An unswapped RGB
        image will render through this WCS profile so that red content will appear blue, and blue content, red.

BGR-Red-Ducati_WCS-Test-TriState.jpg

	This is an RGB jpeg image with the red and blue channels swapped to BGR. This jpeg has the 
        above BGR-Wcs-RBG-Icc-Test.icc profile embedded.

	This image was created to test profile utilization by applications and system components on Windows Vista. In its
        un-channel swapped original form, this is a photo of a _red_ Ducati MotoGP bike. When viewed in an application or via
	a system component, you can immediately tell if the embedded ICC or WCS profile is being used.

	If the motorcycle looks BLUE, the embedded profile is being completely ignored.

	If the motorcycle looks GREEN, the embedded ICC profile is being used. This indicates correct ICC profile support.

	If the motorcycle looks RED, then the WCS profile embedded in the ICC profile is being used, and you are probably
        running on Windows Vista. This indicates correct profile handling on Windows Vista.