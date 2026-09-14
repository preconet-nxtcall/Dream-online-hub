-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 11, 2026 at 02:59 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `fairbiz`
--

-- --------------------------------------------------------

--
-- Table structure for table `agency_cash_book`
--

CREATE TABLE `agency_cash_book` (
  `id` int(11) NOT NULL,
  `agency_id` varchar(50) NOT NULL,
  `recharge_limit_live` varchar(50) NOT NULL,
  `rs_inhand_expected` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `agency_cash_book`
--

INSERT INTO `agency_cash_book` (`id`, `agency_id`, `recharge_limit_live`, `rs_inhand_expected`) VALUES
(1, '1', '99999099', '900'),
(2, '23', '4091', '909');

-- --------------------------------------------------------

--
-- Table structure for table `cmstable`
--

CREATE TABLE `cmstable` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `title` text NOT NULL,
  `slag` text NOT NULL,
  `detail` mediumtext NOT NULL,
  `image` text NOT NULL,
  `show_status` varchar(100) NOT NULL,
  `type` varchar(100) NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cmstable`
--

INSERT INTO `cmstable` (`id`, `name`, `title`, `slag`, `detail`, `image`, `show_status`, `type`, `date`) VALUES
(1, 'Terms & Conditions', 'Kolkata', '1', '<div>Welcome to Office Manager. By accessing or using this CRM platform, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions. Office Manager is designed to help businesses manage customers, employees, projects, sales, invoices, inventory, communications, and other operational activities through a secure and user-friendly system. Your continued use of the platform constitutes your acceptance of these terms, including any future modifications that may be introduced from time to time.</div><div><br></div><div>You agree to use Office Manager only for lawful business purposes and in a manner that does not interfere with the rights of other users or the proper functioning of the platform. You are responsible for maintaining the confidentiality of your login credentials and for all activities carried out under your account. You must ensure that the information you provide is accurate, complete, and regularly updated. Any unauthorized access, misuse, or attempt to compromise the security or integrity of the platform may result in the suspension or termination of your account without prior notice.</div><div><br></div><div>Office Manager makes reasonable efforts to provide reliable and uninterrupted services; however, we do not guarantee that the platform will always be available without delays, interruptions, maintenance periods, or technical issues. We reserve the right to modify, enhance, restrict, or discontinue any feature, functionality, or service at our sole discretion. Users are encouraged to maintain regular backups of their important business data, as Office Manager shall not be held responsible for any loss of information resulting from technical failures, user errors, unauthorized access, third-party services, or circumstances beyond our reasonable control.</div><div><br></div><div>All software, content, trademarks, logos, designs, and intellectual property associated with Office Manager remain the exclusive property of their respective owners and may not be copied, reproduced, modified, distributed, or used without prior written permission. By using this platform, you agree to comply with all applicable laws and regulations. Any disputes arising from the use of Office Manager shall be governed by the applicable laws of the relevant jurisdiction. If any provision of these Terms and Conditions is found to be invalid or unenforceable, the remaining provisions shall continue to remain in full force and effect.</div>', '1784197376_Terms-and-Conditions.avif', 'ACTIVE', 'TERMS', '2026-07-16'),
(2, 'Privacy Policy', '<p>Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.&nbsp;Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.&nbsp;Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.<br></p>', '1', '<div>At Office Manager, we are committed to protecting the privacy and security of our users and their business information. This Privacy Policy explains how we collect, use, store, process, and safeguard the information you provide while using our Customer Relationship Management platform. By accessing or using Office Manager, you acknowledge that you have read and accepted the practices described in this Privacy Policy. We collect information that is necessary to deliver and improve our services, including account details, employee information, customer records, project data, invoices, inventory details, communication logs, and other business-related information entered into the system. We may also collect technical information such as device details, browser type, IP address, login activity, and usage statistics to improve platform performance, enhance security, and provide a better user experience.</div><div><br></div><div>The information collected is used solely for operating the platform, providing customer support, maintaining system security, generating reports, improving features, and communicating important service updates. We do not sell, rent, or trade your personal or business information to third parties for marketing purposes. Information may be shared only with trusted service providers who assist in operating the platform or when required by applicable law, legal process, or regulatory authority. We implement appropriate administrative, technical, and organizational security measures to protect your data against unauthorized access, alteration, disclosure, or destruction. While we strive to use industry-standard security practices, no method of electronic storage or internet transmission can be guaranteed to be completely secure, and users are encouraged to maintain strong passwords and protect their account credentials.</div><div><br></div><div>Users remain the owners of the data they upload to Office Manager and are responsible for ensuring the accuracy and legality of the information they provide. We may retain data for operational, legal, security, or compliance purposes as required by applicable regulations. We reserve the right to update this Privacy Policy whenever necessary to reflect changes in technology, legal requirements, or business operations. Continued use of Office Manager after such updates constitutes acceptance of the revised Privacy Policy, and users are encouraged to review this document periodically to stay informed about how their information is protected.</div>', '1784197432_Privacy.jpg', 'ACTIVE', 'PRIVACY', '2026-07-16'),
(3, 'About Medico Admission Hub', 'Empowering Future Doctors Through Trusted Global Medical Education', 'With over 15 years of experience, Medico Admission Hub is one of India\'s trusted medical education consultancies, dedicated to helping aspiring doctors secure admission to top medical universities across the globe. From personalized career counseling and university selection to visa assistance and post-admission support, we provide end-to-end guidance that makes the journey to an international MBBS degree smooth, transparent, and successful.', '<div style=\"text-align: left;\"><div>Welcome to Medico Admission Hub, India\'s trusted medical education consultancy dedicated to helping aspiring doctors turn their dreams into reality. With over 15 years of experience in the field of medical admissions, we have successfully guided thousands of students toward securing admission to top medical universities across the globe. Our mission is to simplify the complex admission process and provide students with honest, transparent, and professional guidance at every stage of their educational journey.</div><div><br></div><div>At Medico Admission Hub, we understand that pursuing an MBBS degree is one of the most important decisions in a student\'s life. Our team of experienced education consultants works closely with every student to understand their academic profile, career aspirations, and budget before recommending the most suitable universities. We proudly assist students seeking admission to internationally recognized medical universities in Georgia, Russia, Kazakhstan, Uzbekistan, Kyrgyzstan, Bangladesh, Nepal, and Tajikistan, ensuring they receive quality education and global career opportunities.</div><div><br></div><div>Our services extend far beyond university admission. We provide complete end-to-end support, including career counseling, university selection, admission and registration, document verification, translation, notarization, Apostille, attestation, visa invitation, visa processing, travel planning, airport pickup, hostel accommodation, and continuous assistance throughout the student\'s medical education. Our commitment doesn\'t end after admission—we remain available to support students and their families throughout their entire academic journey abroad.</div><div><br></div><div>Over the years, Medico Admission Hub has built strong relationships with leading medical universities and trusted international partners. Our experienced counselors stay updated with the latest admission policies, eligibility requirements, visa regulations, and global medical education trends to ensure students receive accurate and reliable guidance. We believe that every student deserves personalized attention, ethical counseling, and complete transparency throughout the admission process.</div><div><br></div><div>Our success is measured not only by the number of students we have guided but also by the trust families place in us. We take pride in maintaining a high standard of professionalism, integrity, and student satisfaction. From your first counseling session to your graduation day, our dedicated team stands beside you, helping you overcome every challenge with confidence.</div><div><br></div><div>At Medico Admission Hub, we don\'t just help students secure admission—we help them build successful medical careers and shape a brighter future. If you dream of becoming a doctor through international medical education, let our expertise, experience, and commitment guide you every step of the way. Your journey toward a rewarding medical career begins with Medico Admission Hub.</div></div>', '1782375339_About.jpg', 'ACTIVE', 'ABOUT', '2026-06-25'),
(4, 'Build Your Career with Medico Admission Hub', 'Grow Your Career with India\'s Trusted Medical Education Consultancy', 'Join Medico Admission Hub and become part of a passionate team dedicated to shaping the future of medical education. We are looking for motivated, talented, and career-driven professionals who are eager to make a difference in students\' lives. Enjoy a supportive work environment, continuous learning opportunities, professional growth, and the chance to build a rewarding career with one of India\'s leading medical admission consultancies.', '<div><b>Join Our Growing Team</b></div><div><br></div><div>At Medico Admission Hub, we believe that our people are our greatest strength. As one of India\'s leading medical education consultancies with over 15 years of experience, we are committed to helping students achieve their dream of becoming doctors through quality guidance and professional counseling. We are constantly looking for passionate, energetic, and career-oriented individuals who are ready to grow with us and make a meaningful impact in students\' lives.</div><div><br></div><div>If you are passionate about education, communication, and helping students build a brighter future, we invite you to become a part of our dynamic team. We provide a professional work environment, continuous learning opportunities, career growth, and performance-based rewards for dedicated employees.</div><div><br></div><div><b><u>Current Opening</u></b></div><div><br></div><div><b>Marketing Executive (Full-Time)</b></div><div><br></div><div>We are looking for a **Full-Time Marketing Executive** who is enthusiastic, confident, and capable of promoting our medical admission services both online and offline. The ideal candidate should have excellent communication skills, a positive attitude, and the ability to build strong relationships with students, parents, schools, and educational institutions.</div><div><br></div><div><b>Key Responsibilities</b></div><div><br></div><div>* Promote MBBS admission services across India.</div><div>* Generate student leads through online and offline marketing.</div><div>* Visit schools, colleges, coaching centers, and educational events.</div><div>* Conduct student counseling and explain admission procedures.</div><div>* Build relationships with educational partners and institutions.</div><div>* Follow up with prospective students and parents.</div><div>* Coordinate with the admissions team to achieve enrollment targets.</div><div>* Support digital marketing campaigns and promotional activities.</div><div>* Maintain accurate records of leads and customer interactions.</div><div>* Represent Medico Admission Hub with professionalism and integrity.</div><div><br></div><div><b>Required Skills</b></div><div><br></div><div>* Excellent communication and interpersonal skills.</div><div>* Good presentation and convincing ability.</div><div>* Basic computer and internet knowledge.</div><div>* Positive attitude with a willingness to travel when required.</div><div>* Ability to work independently as well as in a team.</div><div>* Strong problem-solving and organizational skills.</div><div><br></div><div><b> Eligibility</b></div><div><br></div><div>* Graduate in any discipline (MBA or Marketing background preferred).</div><div>* Freshers with excellent communication skills are welcome.</div><div>* Experience in Education, Sales, Counseling, or Marketing will be an added advantage.</div><div>* Fluency in English, Hindi, or regional languages is preferred.</div><div><br></div><div><b>Why Join Medico Admission Hub?</b></div><div><br></div><div>* Work with one of India\'s trusted medical education consultancies.</div><div>* Attractive salary with performance incentives.</div><div>* Career growth and leadership opportunities.</div><div>* Friendly and supportive work environment.</div><div>* Professional training and skill development.</div><div>* Opportunity to interact with students from across India.</div><div>* Performance recognition and career advancement.</div><div>* Long-term and stable employment.</div><div><br></div><div><u>Apply Today</u></div><div><br></div><div>If you are passionate about helping students achieve their dream of studying MBBS abroad and want to build a rewarding career in the education industry, we\'d love to hear from you.</div><div><br></div><div>**Send your updated resume today and become a part of the Medico Admission Hub family. Together, let\'s shape the future of aspiring doctors across the globe.**</div><div><br></div>', '1782375551_Career.png', 'ACTIVE', 'CAREER', '2026-06-25'),
(125, 'NEET-UG Guidance & Admission Support', 'Expert NEET-UG Guidance for Your MBBS Admission Journey', 'Take the first step toward your dream medical career with Medico Admission Hub. Our experienced counselors provide complete guidance for NEET-UG, including eligibility, counseling, university selection, admission support, and career planning. Whether you aim to study MBBS in India or abroad, we help you make informed decisions and secure admission to the right medical university with confidence.', '<div><span style=\"font-size: 14px;\"><b>Your First Step Towards Becoming a Doctor</b></span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">The National Eligibility cum Entrance Test (NEET-UG) is the gateway for students aspiring to pursue MBBS, BDS, and other undergraduate medical courses in India and abroad. At Medico Admission Hub, we understand that qualifying NEET is one of the most important milestones in every medical student\'s journey. With over 15 years of experience in medical education counseling, we provide complete guidance to help students confidently navigate the NEET admission process and secure admission to reputed medical universities.</span></div><div><span style=\"font-size: 14px;\">Whether you are planning to study MBBS in India or pursue your medical education abroad, our experienced counselors provide personalized assistance based on your NEET score, academic performance, budget, and career aspirations. We help students understand the complete admission process, eligibility criteria, counseling procedures, university selection, documentation, and career opportunities available after qualifying NEET-UG.</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\"><b>Why is NEET-UG Important?</b></span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">NEET-UG is the mandatory entrance examination for admission to undergraduate medical courses in India and is also accepted by many international medical universities for Indian students. Qualifying NEET allows students to pursue MBBS education while meeting the eligibility requirements prescribed by the National Medical Commission (NMC) for studying medicine abroad.</span></div><div><span style=\"font-size: 14px;\">A good NEET score increases your chances of securing admission to reputed medical colleges and provides access to multiple career opportunities in the healthcare sector. Even if you do not secure a government medical seat, numerous internationally recognized universities offer quality MBBS programs that accept NEET-qualified students.</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\"><b>Our NEET-UG Admission Services</b></span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">At Medico Admission Hub, we provide complete admission support, including:</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">Personalized Career Counseling</span></div><div><span style=\"font-size: 14px;\">NEET Score Evaluation</span></div><div><span style=\"font-size: 14px;\">University &amp; Country Selection</span></div><div><span style=\"font-size: 14px;\">MBBS Admission Guidance</span></div><div><span style=\"font-size: 14px;\">Application &amp; Registration Assistance</span></div><div><span style=\"font-size: 14px;\">Document Verification</span></div><div><span style=\"font-size: 14px;\">Visa Processing Support</span></div><div><span style=\"font-size: 14px;\">Travel &amp; Accommodation Assistance</span></div><div><span style=\"font-size: 14px;\">Pre-Departure Orientation</span></div><div><span style=\"font-size: 14px;\">Post-Admission Student Support</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">Our experienced counselors carefully analyze each student\'s academic profile and recommend the most suitable medical universities based on their goals and budget.</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\"><b>Study MBBS Abroad After NEET</b></span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">Students who qualify NEET can explore excellent opportunities to study MBBS at internationally recognized medical universities. We assist admissions to top universities in:</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">Georgia</span></div><div><span style=\"font-size: 14px;\">Russia</span></div><div><span style=\"font-size: 14px;\">Kazakhstan</span></div><div><span style=\"font-size: 14px;\">Uzbekistan</span></div><div><span style=\"font-size: 14px;\">Kyrgyzstan</span></div><div><span style=\"font-size: 14px;\">Bangladesh</span></div><div><span style=\"font-size: 14px;\">Nepal</span></div><div><span style=\"font-size: 14px;\">Tajikistan</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">These countries offer affordable tuition fees, English-medium MBBS programs, modern medical infrastructure, experienced faculty, advanced clinical training, and globally recognized medical degrees. Students receive high-quality education while gaining international exposure and valuable practical experience.</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\"><b>Why Choose Medico Admission Hub?</b></span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">With more than 15 years of expertise, Medico Admission Hub has successfully guided thousands of students toward fulfilling their dream of becoming doctors. Our experienced team provides transparent counseling, ethical guidance, and complete support throughout the admission journey. From selecting the right university to visa processing and travel arrangements, we ensure a smooth and hassle-free experience for every student.</span></div><div><span style=\"font-size: 14px;\">Our commitment doesn\'t end after admission. We continue supporting students throughout their academic journey, helping them adapt to university life and achieve long-term success in their medical careers.</span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\"><b>Begin Your Medical Journey Today</b></span></div><div><span style=\"font-size: 14px;\"><br></span></div><div><span style=\"font-size: 14px;\">Your dream of becoming a doctor begins with the right guidance. If you have qualified NEET-UG or are planning your MBBS admission, connect with the experts at Medico Admission Hub. We will help you choose the best university, complete your admission process, and take the first step toward a successful career in medicine.</span></div><div><span style=\"font-size: 14px;\">Apply today and let Medico Admission Hub guide you towards a brighter future in medical education.</span></div>', '1782375669_NEET-UG.png', 'ACTIVE', 'NEET-UG', '2026-06-26'),
(126, 'NEET-PG Guidance & Career Counseling', 'Expert NEET-PG Counseling for a Successful Medical Specialization', 'Advance your medical career with professional NEET-PG guidance from Medico Admission Hub. Our experienced counselors provide complete support for postgraduate medical admissions, including career counseling, specialization selection, counseling assistance, medical college guidance, and admission planning. We help you choose the right path toward a successful future in MD, MS, and other postgraduate medical programs.', '<div>Advance Your Medical Career with Expert NEET-PG Guidance</div><div><br></div><div>NEET-PG (National Eligibility cum Entrance Test for Postgraduate) is one of the most important examinations for MBBS graduates who aspire to pursue postgraduate medical education in India. It serves as the gateway to MD, MS, PG Diploma, and various postgraduate medical programs offered by government, private, and deemed medical institutions. At Medico Admission Hub, we provide expert guidance and personalized counseling to help medical graduates make informed decisions about their postgraduate medical careers.</div><div><br></div><div>With over 15 years of experience in medical education consultancy, we assist students in understanding NEET-PG counseling procedures, seat allocation, college selection, documentation, and admission requirements. Our experienced counselors work closely with every candidate to identify the best postgraduate opportunities based on their NEET-PG score, preferred specialization, academic background, career goals, and budget.</div><div><br></div><div>Why Choose NEET-PG?</div><div><br></div><div>NEET-PG is the primary entrance examination for admission to postgraduate medical courses in India. A good NEET-PG score enables students to pursue specialized medical education in disciplines such as General Medicine, Surgery, Pediatrics, Orthopedics, Radiology, Dermatology, Obstetrics & Gynecology, Anesthesiology, Psychiatry, and many other clinical and non-clinical branches.</div><div><br></div><div>Postgraduate medical education allows doctors to gain advanced knowledge, develop specialized clinical skills, and enhance their career prospects in hospitals, healthcare organizations, research institutions, and academic medical centers.</div><div><br></div><div>Our NEET-PG Admission Services</div><div><br></div><div>Medico Admission Hub provides complete assistance throughout the admission journey, including:</div><div><br></div><div>Personalized Career Counseling</div><div>NEET-PG Score Evaluation</div><div>MD/MS & PG Diploma Guidance</div><div>Medical College Selection</div><div>Counseling Registration Support</div><div>Choice Filling Assistance</div><div>Document Verification</div><div>Admission Process Guidance</div><div>Seat Allotment Support</div><div>Career Planning & Expert Advice</div><div><br></div><div>Our team carefully evaluates every student\'s profile and recommends the most suitable colleges and specializations according to their career aspirations.</div><div><br></div><div>Explore Higher Medical Education Opportunities</div><div><br></div><div>In addition to postgraduate admission guidance in India, we also provide expert counseling for international medical education opportunities where applicable. Our experienced advisors help students understand admission requirements, eligibility criteria, university options, and future career pathways.</div><div><br></div><div>Whether you wish to pursue postgraduate studies in India or explore recognized international opportunities, our team provides transparent guidance and professional support throughout the entire process.</div><div><br></div><div>Why Choose Medico Admission Hub?</div><div><br></div><div>At Medico Admission Hub, we are committed to helping medical graduates achieve their professional goals through reliable counseling and personalized support. Our experienced consultants stay updated with the latest NEET-PG counseling guidelines, admission policies, and medical education trends to provide accurate and trustworthy advice.</div><div><br></div><div>We believe every doctor deserves expert guidance while choosing a specialization that aligns with their interests and long-term career objectives. Our transparent counseling process, student-first approach, and dedicated support have earned the trust of thousands of aspiring medical professionals.</div><div><br></div><div>Take the Next Step in Your Medical Career</div><div><br></div><div>Your MBBS degree is only the beginning of your medical journey. A postgraduate qualification can open the door to greater clinical expertise, better career opportunities, and professional growth. If you are preparing for NEET-PG or planning your postgraduate medical admission, Medico Admission Hub is here to guide you every step of the way.</div><div><br></div><div>Contact our expert counselors today and begin your journey toward a successful postgraduate medical career with confidence.</div>', '1782375740_NEET-PG.png', 'ACTIVE', 'NEET-PG', '2026-06-25'),
(128, 'Abroad Medical Examination Guidance', 'Your Gateway to International Medical Licensing & Global Career Opportunities', 'Prepare for a successful international medical career with expert guidance from Medico Admission Hub. We provide comprehensive counseling for major medical licensing and qualification examinations, including FMGE, NExT, USMLE, PLAB, AMC, MCCQE, DHA, HAAD, MOH, and more. Our experienced advisors help you understand eligibility, examination pathways, career opportunities, and the steps needed to achieve your dream of practicing medicine anywhere in the world.', '<div>Prepare for International Medical Licensing & Eligibility Examinations</div><div><br></div><div>Studying MBBS abroad is the first step toward building a successful medical career. To practice medicine in different countries, graduates are often required to qualify the medical licensing or eligibility examinations specified by the respective medical authorities. At Medico Admission Hub, we provide complete guidance to help students understand these examinations, plan their career pathways, and prepare for future medical licensing requirements with confidence.</div><div><br></div><div>With over 15 years of experience in medical education consultancy, we assist students from the beginning of their admission journey until they are ready to pursue higher education, internships, or medical practice. Our expert counselors provide personalized advice on international licensing examinations, eligibility requirements, documentation, and career opportunities after completing an MBBS degree abroad.</div><div><br></div><div>International Medical Licensing Examinations</div><div><br></div><div>Medical graduates may need to qualify licensing or eligibility examinations depending on the country where they intend to practice medicine. Some of the well-known examinations include:</div><div><br></div><div>FMGE (India)</div><div>NExT (India)</div><div>USMLE (United States)</div><div>PLAB (United Kingdom)</div><div>AMC (Australia)</div><div>MCCQE (Canada)</div><div>DHA (Dubai)</div><div>HAAD / DOH (Abu Dhabi)</div><div>MOH (UAE)</div><div>Prometric Examinations (Gulf Countries)</div><div><br></div><div>Each examination has its own eligibility criteria, examination pattern, and registration process. Our experienced counselors help students understand these pathways and choose the most suitable career direction based on their future goals.</div><div><br></div><div>Our Guidance Services</div><div><br></div><div>At Medico Admission Hub, we provide complete support for students planning their international medical careers, including:</div><div><br></div><div>Career Counseling</div><div>Examination Pathway Guidance</div><div>Country-wise Licensing Information</div><div>Eligibility Assessment</div><div>University Selection Support</div><div>Documentation Guidance</div><div>Internship & Clinical Training Information</div><div>Postgraduate Career Planning</div><div>Personalized Academic Counseling</div><div>Continuous Student Support</div><div><br></div><div>Our objective is to help students understand the complete roadmap from MBBS admission to becoming a licensed medical professional.</div><div><br></div><div>Why Choose International Medical Education?</div><div><br></div><div>An internationally recognized MBBS degree offers students access to advanced medical education, modern healthcare systems, global clinical exposure, and diverse career opportunities. Students gain valuable practical experience, interact with patients from different backgrounds, and develop the knowledge and confidence required for successful medical practice.</div><div><br></div><div>With proper planning and guidance, graduates can explore postgraduate education, research opportunities, hospital practice, and healthcare careers in different parts of the world, subject to the licensing regulations of each country.</div><div><br></div><div>Why Choose Medico Admission Hub?</div><div><br></div><div>At Medico Admission Hub, we believe that every student\'s journey extends far beyond university admission. Our experienced team provides continuous guidance throughout your medical education, helping you understand licensing examinations, postgraduate options, and international career opportunities.</div><div><br></div><div>We stay updated with changing medical education policies, licensing requirements, and global healthcare trends to provide students with accurate, transparent, and reliable guidance. Our personalized counseling ensures that every student receives the right advice according to their career aspirations and preferred destination.</div><div><br></div><div>Build Your Global Medical Career</div><div><br></div><div>Your dream of becoming a successful doctor doesn\'t end with earning an MBBS degree—it continues with professional growth, specialization, and international career opportunities. Whether you aspire to practice medicine in India, the United States, the United Kingdom, Australia, Canada, the Middle East, or other countries, Medico Admission Hub is here to guide you at every stage.</div><div><br></div><div>Connect with our expert counselors today and take the next step toward building a successful global medical career with confidence and clarity.</div>', '1782375844_ABROAD-EXAM.webp', 'ACTIVE', 'ABROAD-EXAM', '2026-06-25'),
(131, 'MBBS Scholarship Assistance', 'Unlock Scholarship Opportunities for Your MBBS Abroad Journey', 'Achieve your dream of studying MBBS abroad with expert scholarship guidance from Medico Admission Hub. We help students explore merit-based scholarships, tuition fee concessions, and financial assistance offered by leading medical universities. Our experienced counselors provide end-to-end support, from eligibility assessment and university selection to scholarship applications, making quality medical education more affordable and accessible.', '<div>Make Your Medical Dream More Affordable</div><div><br></div><div>At Medico Admission Hub, we believe that financial limitations should never prevent talented students from pursuing their dream of becoming doctors. Many internationally recognized medical universities offer scholarships, tuition fee concessions, merit-based awards, and financial assistance to deserving students. Our experienced counselors help students identify suitable scholarship opportunities and guide them through the complete application process.</div><div><br></div><div>With over 15 years of experience in medical education consultancy, we have helped thousands of students secure admissions to leading medical universities abroad. Our scholarship guidance is designed to help students reduce their educational expenses while receiving a world-class medical education.</div><div><br></div><div>Scholarship Opportunities for MBBS Students</div><div><br></div><div>Several medical universities provide scholarship programs based on:</div><div><br></div><div>Academic Excellence</div><div>NEET Performance</div><div>Merit-Based Selection</div><div>Outstanding School Results</div><div>University Entrance Performance</div><div>Early Admission Benefits</div><div>Special International Student Scholarships</div><div>Annual Academic Performance</div><div>University-Specific Financial Aid</div><div><br></div><div>Scholarship availability, eligibility, and award amounts may vary depending on the university, country, and admission year.</div><div><br></div><div>Our Scholarship Assistance Services</div><div><br></div><div>At Medico Admission Hub, we provide complete guidance throughout the scholarship process, including:</div><div><br></div><div>Scholarship Eligibility Assessment</div><div>University Selection</div><div>Merit Evaluation</div><div>Scholarship Application Assistance</div><div>Document Preparation</div><div>Admission & Scholarship Coordination</div><div>Interview Preparation (if required)</div><div>Application Tracking</div><div>Continuous Counseling</div><div>Admission Support</div><div><br></div><div>Our experienced team carefully evaluates every student\'s academic profile and recommends universities that may offer suitable scholarship opportunities.</div><div><br></div><div>Countries We Support</div><div><br></div><div>We assist students seeking MBBS admissions with scholarship guidance in leading medical education destinations, including:</div><div><br></div><div>Georgia</div><div>Russia</div><div>Kazakhstan</div><div>Uzbekistan</div><div>Kyrgyzstan</div><div>Bangladesh</div><div>Nepal</div><div>Tajikistan</div><div><br></div><div>Many universities in these countries provide financial assistance and merit-based scholarships to eligible international students while maintaining high academic standards and modern medical infrastructure.</div><div><br></div><div>Why Choose Medico Admission Hub?</div><div><br></div><div>Choosing the right university is about more than just tuition fees—it\'s about finding the best value for your education. Our expert counselors compare universities based on academic quality, scholarship opportunities, affordability, living expenses, and long-term career prospects.</div><div><br></div><div>We provide honest and transparent guidance, ensuring students understand the scholarship process, eligibility requirements, and application deadlines. From the initial counseling session to successful admission, we remain committed to helping students make informed decisions.</div><div><br></div><div>Start Your Scholarship Journey Today</div><div><br></div><div>A scholarship can significantly reduce the financial burden of pursuing an MBBS degree abroad while allowing you to focus on achieving academic excellence. If you are planning to study medicine overseas, let Medico Admission Hub help you explore available scholarship opportunities and choose the university that best fits your goals.</div><div><br></div><div>Our dedicated team is ready to guide you through every step of the admission and scholarship process, making your dream of becoming a doctor more accessible and affordable.</div><div><br></div><div>Contact Medico Admission Hub today and discover the scholarship opportunities that can help shape your future in medicine.</div>', '1782375929_SCHOLARSHIP.jpg', 'ACTIVE', 'SCHOLARSHIP', '2026-06-25'),
(138, 'Medical Exam Preparation Guidance', 'Expert Exam Preparation for Future Medical Professionals', 'Build a strong foundation for your medical career with comprehensive exam preparation guidance from Medico Admission Hub. We provide expert support for NEET-UG, NEET-PG, FMGE, NExT, USMLE, PLAB, AMC, and other medical licensing examinations. Our personalized counseling, strategic preparation plans, and career-focused guidance help students achieve academic excellence and confidently pursue medical opportunities in India and abroad.', '<div><b>Prepare with Confidence for Your Medical Career</b></div><div><br></div><div>Success in the medical profession requires more than earning an MBBS degree—it also involves qualifying important medical licensing and entrance examinations. At Medico Admission Hub, we provide expert guidance and personalized counseling to help students prepare for the examinations that shape their future medical careers. With over 15 years of experience in medical education consultancy, we understand the challenges students face and provide the right direction to help them achieve their goals.</div><div><br></div><div>Whether you are preparing for NEET-UG, NEET-PG, FMGE, NExT, USMLE, PLAB, AMC, MCCQE, or other international medical licensing examinations, our experienced counselors help you understand the examination process, eligibility requirements, career pathways, and preparation strategies.</div><div><br></div><div><b>Examinations We Guide Students For</b></div><div><br></div><div>We provide guidance for a wide range of national and international medical examinations, including:</div><div><br></div><div>NEET-UG</div><div>NEET-PG</div><div>FMGE (Foreign Medical Graduate Examination)</div><div>NExT (National Exit Test)</div><div>USMLE (United States Medical Licensing Examination)</div><div>PLAB (United Kingdom)</div><div>AMC (Australian Medical Council Examination)</div><div>MCCQE (Medical Council of Canada Qualifying Examination)</div><div>DHA / HAAD / MOH Licensing Examinations</div><div><br></div><div><b>Other International Medical Licensing Exams</b></div><div><br></div><div>Our counselors help students understand each examination\'s eligibility, syllabus, registration process, and career opportunities.</div><div><br></div><div><b>Our Exam Preparation Support</b></div><div><br></div><div>At Medico Admission Hub, we provide complete academic guidance to help students confidently prepare for their future examinations. Our services include:</div><div><br></div><div>Personalized Career Counseling</div><div>Examination Roadmap Planning</div><div>Country-wise Licensing Guidance</div><div>Eligibility Assessment</div><div>University Selection Support</div><div>Study Planning &amp; Preparation Strategy</div><div>Academic Mentoring</div><div>Documentation Guidance</div><div>Internship &amp; Career Advice</div><div>Continuous Student Support</div><div><br></div><div>We believe that proper planning and expert guidance significantly improve a student\'s confidence and long-term career success.</div><div><br></div><div><b>Why Choose Medico Admission Hub?</b></div><div><br></div><div>With more than 15 years of experience, Medico Admission Hub has successfully guided thousands of aspiring doctors toward quality medical education and successful careers. Our expert counselors stay updated with the latest examination patterns, medical education policies, licensing requirements, and global healthcare trends to provide students with accurate and reliable guidance.</div><div>We work closely with every student to understand their academic background, career goals, and preferred destination before recommending the most suitable preparation pathway. Our transparent counseling process and student-focused approach ensure that every candidate receives personalized guidance throughout their journey.</div><div><br></div><div><b>Build a Successful Medical Career</b></div><div><br></div><div>Preparing for medical examinations is an important step toward becoming a licensed healthcare professional. With the right strategy, expert guidance, and consistent preparation, students can confidently achieve their career goals and unlock opportunities in India and around the world.</div><div>Whether you plan to practice medicine in India, pursue postgraduate education abroad, or obtain international medical licensure, Medico Admission Hub is committed to supporting you throughout your journey.</div><div>Our mission is not only to help students gain admission to leading medical universities but also to guide them toward long-term academic success and rewarding medical careers.</div><div>Take the next step toward your dream medical career. Contact Medico Admission Hub today and let our experienced experts help you prepare for success.</div>', '1782376026_EXAM-PREPARATION.jpg', 'ACTIVE', 'EXAM-PREPARATION', '2026-06-26'),
(140, 'Sneha Das', 'MBBS Student, Caucasus University', '4', 'I sincerely thank the entire team for helping me achieve my dream of studying MBBS abroad. Their experienced counselors made every step easy, from admission and visa assistance to travel planning and university orientation. They genuinely care about students and continue to provide support even after admission. I feel confident knowing that I have a reliable team guiding me throughout my medical education. I strongly recommend them to every aspiring doctor.', '1782374929_Testimonial.png', 'ACTIVE', 'TESTIMONIAL', '2026-06-25'),
(141, 'Arjun Kumar Singh', 'MBBS Student, Alte University', '3', 'The entire admission process was transparent and well-organized. Every document was carefully verified, and the team kept me informed throughout each stage of my application. Even after reaching Georgia, they continued supporting me with accommodation, university registration, and local guidance. Their commitment to student success is truly impressive. I am grateful for their continuous support throughout my MBBS journey.', '1782374889_Testimonial.png', 'ACTIVE', 'TESTIMONIAL', '2026-06-25'),
(142, 'Priya Verma', 'MBBS Student, University of Georgia', '2', 'I was initially confused about choosing the right country and university for my medical studies. The expert counselors provided clear guidance, explained every detail, and helped me select the perfect university according to my budget and career goals. Their support during documentation, visa approval, and airport assistance was exceptional. Thanks to their dedication, my admission process was smooth and completely stress-free.', '1782374848_Testimonial.png', 'ACTIVE', 'TESTIMONIAL', '2026-06-25'),
(143, 'Rahul Sharma', 'MBBS Student, Georgian American University (GAU)', '1', 'Choosing this consultancy was one of the best decisions of my life. From university selection to visa processing and travel arrangements, everything was handled professionally. The counselors were always available to answer my questions and guided me through every step of the admission process. Today, I am happily pursuing my MBBS in Georgia and receiving quality education in a modern medical university. I highly recommend their services to every student who dreams of studying MBBS abroad.', '1782374794_Testimonial.jpeg', 'ACTIVE', 'TESTIMONIAL', '2026-06-25'),
(170, 'Gallery Image', 'TRAVEL', '4', '6aGXr302-k4?si=MgpxkGDdoV79hgiC', '1782375095_Gallery.webp', 'ACTIVE', 'GALLERY', '2026-06-25'),
(171, 'Gallery Image', 'TRAVEL', '3', 'DkB3D6g2hSQ?si=m6bGwSg4RAoEN8tM', '1782375079_Gallery.webp', 'ACTIVE', 'GALLERY', '2026-06-25'),
(172, 'Luxury Living Room Makeover Experience', 'In this video, we present a complete transformation of a workspace into a modern and productive office environment. At My Space Planner, we understand that a well-designed office plays a crucial role in enhancing efficiency, creativity, and employee satisfaction. This project demonstrates how strategic design can positively impact a business environment.\r\n\r\nThe project began with understanding the client\'s brand identity and workspace requirements. We designed a layout that balances open work areas with private zones to support both collaboration and focused work. The use of modern furniture, ergonomic seating, and efficient desk layouts ensures comfort and productivity throughout the day.', '3', '0__TF8mzLBE?si=98NdOjNPsSHCTdwJ', '1775891346_Video.jpeg', 'ACTIVE', 'VIDEO', '2026-04-11'),
(173, 'Manage Your Office Smarter', 'About Us', 'All-in-one CRM to manage employees, clients, leads, tasks, attendance, inventory, invoices, and daily business operations from a single dashboard.', '#', '1784883728_Slider.png', 'ACTIVE', 'HOME-SLIDE', '2026-07-24'),
(174, 'Gallery Image', 'TRAVEL', '2', '', '1782375065_Gallery.jpg', 'ACTIVE', 'GALLERY', '2026-06-25'),
(175, 'Gallery Image', 'TRAVEL', '1', '', '1782375053_Gallery.jpg', 'ACTIVE', 'GALLERY', '2026-06-25'),
(176, 'Company', '', '8', '', '1775642107_Partner.jpg', 'ACTIVE', 'PARTNER', '2026-04-08'),
(177, 'Gallery Image', 'CAMPUS', '4', '', '1782375039_Gallery.png', 'ACTIVE', 'GALLERY', '2026-06-25'),
(178, 'Gallery Image', 'CAMPUS', '3', '', '1782375005_Gallery.png', 'ACTIVE', 'GALLERY', '2026-06-25'),
(179, 'Gallery Image', 'CAMPUS', '2', '', '1782374988_Gallery.png', 'ACTIVE', 'GALLERY', '2026-06-25'),
(180, 'Gallery Image', 'CAMPUS', '1', '', '1782374972_Gallery.png', 'ACTIVE', 'GALLERY', '2026-06-25'),
(181, 'Boost Productivity & Collaboration', 'Subscriptions', 'Assign tasks, track progress, monitor performance, automate reminders, and keep your entire team connected in real time.', '#', '1784883714_Slider.png', 'ACTIVE', 'HOME-SLIDE', '2026-07-24'),
(182, 'Grow Your Business with Confidence', 'Recharge', 'Powerful analytics, customer management, billing, reports, and workflow automation to help your business scale faster and work more efficiently.', '#', '1784883629_Slider.png', 'ACTIVE', 'HOME-SLIDE', '2026-07-24');

-- --------------------------------------------------------

--
-- Table structure for table `contact`
--

CREATE TABLE `contact` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `emp_id` varchar(20) NOT NULL,
  `phone` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `sub` text NOT NULL,
  `msg` text NOT NULL,
  `read_status` varchar(100) NOT NULL,
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `contact`
--

INSERT INTO `contact` (`id`, `name`, `user_id`, `emp_id`, `phone`, `email`, `sub`, `msg`, `read_status`, `date`) VALUES
(81, 'Lorem Ipsum', '22', '1', '9000000000', 'sample@gmail.com', 'test', 'tEST mESSAGE', 'PENDING', '2025-12-17'),
(82, 'Lorem Ipsum', '22', '1', '09000000000', 'sample@gmail.com', 'test', 'test message', 'PENDING', '2026-01-06'),
(83, 'Lorem Ipsum', '22', '1', '09000000000', 'sample@gmail.com', 'test', 'Test Message', 'PENDING', '2026-04-09'),
(84, 'Lorem Ipsum', '22', '1', '9000000000', 'sample@gmail.com', 'test', 'message', 'PENDING', '2026-04-16'),
(85, 'Lorem Ipsum', '24', '23', '0900000000', 'sample@gmail.com', 'my message', 'test', 'PENDING', '2026-04-30'),
(86, 'Lorem Ipsum', '24', '23', '09000000000', 'sample@gmail.com', '', '', 'PENDING', '2026-07-18'),
(87, 'Lorem Ipsum', '24', '23', '09000000000', 'santanu.preconet@gmail.com', '', '', 'PENDING', '2026-07-18'),
(88, 'Lorem Ipsum', '24', '23', '09000000000', 'sample@gmail.com', '', '', 'PENDING', '2026-07-18'),
(89, 'Lorem Ipsum', '24', '23', '09000000000', 'sample@gmail.com', '', '', 'PENDING', '2026-07-18'),
(90, 'Lorem Ipsum', '24', '23', '09000000000', 'sample@gmail.com', 'test', 'message', 'READ', '2026-07-18');

-- --------------------------------------------------------

--
-- Table structure for table `expense`
--

CREATE TABLE `expense` (
  `id` int(11) NOT NULL,
  `head_id` varchar(20) NOT NULL,
  `emp_id` varchar(20) NOT NULL,
  `amount` varchar(20) NOT NULL,
  `bank_id` varchar(20) NOT NULL,
  `bank_name` varchar(150) NOT NULL,
  `bank_slag` varchar(150) NOT NULL,
  `transection_id` varchar(20) NOT NULL,
  `image` text NOT NULL,
  `remark` text NOT NULL,
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `expense_heads`
--

CREATE TABLE `expense_heads` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `slag` varchar(150) NOT NULL,
  `use_for` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `expense_heads`
--

INSERT INTO `expense_heads` (`id`, `name`, `slag`, `use_for`) VALUES
(1, 'Cash Wthdraw', 'cash-wthdraw', 'ADMIN'),
(2, 'Personal Cash Withdraw', 'personal-cash-withdraw', 'AGENCY'),
(3, 'Ceremony Expence', 'ceremony-expence', 'AGENCY'),
(4, 'Office Expence', 'office-expence', 'ADMIN');

-- --------------------------------------------------------

--
-- Table structure for table `features`
--

CREATE TABLE `features` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `slag` varchar(100) NOT NULL,
  `order_no` varchar(50) NOT NULL,
  `detail` mediumtext NOT NULL,
  `image` text NOT NULL,
  `admin_payment_receive` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `show_status` varchar(100) NOT NULL,
  `date_ts` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `features`
--

INSERT INTO `features` (`id`, `name`, `slag`, `order_no`, `detail`, `image`, `admin_payment_receive`, `type`, `show_status`, `date_ts`) VALUES
(304, 'NovaGlow RGB Mouse Pad', 'novaglow-rgb-mouse-pad', '1', 'Large gaming mouse pad with a smooth tracking surface, anti-slip base, and customizable RGB edge lighting.', '1782370501_Service_Image.png', '', 'PRODUCT', 'ACTIVE', '1782370501'),
(305, 'TitanStrike Mobile Gamepad', 'titanstrike-mobile-gamepad', '2', 'Ergonomic mobile gaming controller with responsive triggers, comfortable grips, and an adjustable smartphone holder.', '1782370451_Service_Image.png', '', 'PRODUCT', 'ACTIVE', '1782370451'),
(308, 'RapidTap Pro Finger Sleeves', 'rapidtap-pro-finger-sleeves', '3', 'Breathable touchscreen gaming finger sleeves offering smooth swipes, reduced sweat, and improved touch responsiveness.', '1782370388_Service_Image.png', '', 'PRODUCT', 'ACTIVE', '1782370388'),
(311, '500', '1', '329', '<div>Studying MBBS abroad has become increasingly popular among Indian students due to the growing demand for quality medical education and global career opportunities. Many internationally recognized universities offer modern infrastructure, experienced faculty, advanced laboratories, and practical clinical exposure that help students build successful medical careers.</div><div><br></div><div>One of the biggest advantages is affordable tuition fees compared to many private medical colleges. Students also benefit from internationally recognized medical degrees, multicultural learning environments, and exposure to modern healthcare systems. These experiences enhance both professional knowledge and personal development.</div><div><br></div><div>Medical universities abroad emphasize practical training through hospitals, research centers, simulation laboratories, and clinical internships. Students interact with patients from different backgrounds, improving communication skills and gaining valuable real-world experience.</div><div><br></div><div>International education also provides opportunities to build global networks, improve English communication, and develop confidence in multicultural environments. Living abroad encourages independence, adaptability, leadership, and problem-solving abilities—qualities that are highly valuable in the medical profession.</div><div><br></div><div>However, choosing the right university requires careful research. Students should consider university recognition, language of instruction, clinical training opportunities, accommodation, safety, and future licensing examination requirements before making a decision.</div><div><br></div><div>With proper planning and guidance, studying MBBS abroad can become an excellent investment in a student\'s future. It offers world-class education, international exposure, and opportunities to pursue successful medical careers both nationally and internationally.</div>', '1784634049_QR.png', '', 'QR', 'ACTIVE', '1782370832'),
(312, '1000', '1', '330', '<p class=\"isSelectedEnd\">Studying MBBS abroad has become an excellent option for students seeking high-quality medical education at affordable costs. While the admission process may seem complicated at first, understanding each step can make the journey simple and stress-free.</p><p class=\"isSelectedEnd\">The process begins with selecting a suitable country and medical university based on eligibility, academic performance, budget, and career aspirations. Once the university is selected, students gather essential documents such as passports, academic certificates, photographs, birth certificates, and medical reports. These documents are verified before submitting the admission application.</p><p class=\"isSelectedEnd\">After successful application review, the university issues an admission letter confirming provisional acceptance. Students then complete additional formalities such as invitation letter processing, document attestation, visa application, and medical insurance. Careful attention to deadlines and documentation is essential throughout the process.</p><p class=\"isSelectedEnd\">Before departure, students receive travel guidance, accommodation support, and orientation sessions covering university life, immigration procedures, airport formalities, and local regulations. Upon arrival, universities usually provide registration assistance and hostel accommodation for international students.</p><p class=\"isSelectedEnd\">Working with an experienced education consultant helps students avoid delays, complete documentation correctly, and receive professional support during every stage of admission. From choosing the right university to reaching the campus safely, expert guidance ensures a smooth experience.</p><p>By understanding the admission process in advance and preparing all necessary documents carefully, aspiring doctors can confidently begin their international medical education and focus on achieving academic excellence.</p>', '1784634038_QR.png', '', 'QR', 'ACTIVE', '1782370782'),
(313, '2000', '1', '331', '<div>Choosing the right country for studying MBBS abroad is one of the most important decisions in a student\'s medical career. Every year, thousands of Indian students explore international medical universities because of affordable tuition fees, globally recognized degrees, and excellent career opportunities. However, selecting the right destination requires careful planning and proper guidance.</div><div><br></div><div>Before making a decision, students should compare factors such as university recognition, tuition fees, living expenses, climate, language of instruction, safety, internship opportunities, and licensing examination eligibility. Countries like Russia, Kazakhstan, Uzbekistan, Georgia, Kyrgyzstan, Nepal, Bangladesh, and the Philippines have become popular choices due to their quality medical education and affordable fee structures.</div><div><br></div><div>Students should also verify whether the university is recognized by relevant medical authorities and whether graduates are eligible to appear for medical licensing examinations required in their home country or future practice destination. Accommodation facilities, student support services, campus infrastructure, and international student communities also play an important role in ensuring a comfortable educational experience.</div><div><br></div><div>Professional guidance can simplify the university selection process by matching your academic profile, budget, and career goals with suitable institutions. A trusted study abroad consultant helps students understand admission requirements, visa procedures, and documentation while avoiding common mistakes.</div><div><br></div><div>Studying MBBS abroad is a life-changing opportunity that opens doors to global medical careers. With proper research, expert counseling, and careful planning, students can confidently choose the destination that best supports their dreams of becoming successful medical professionals.</div>', '1784634028_QR.png', '', 'QR', 'ACTIVE', '1782370745'),
(317, 'GripForce Gaming Hand Gear', 'gripforce-gaming-hand-gear', '4', 'Lightweight gaming finger and hand support designed for better grip, comfort, and control during extended gameplay.', '1782370543_Service_Image.png', '', 'PRODUCT', 'ACTIVE', '1782370543'),
(318, 'FrostCore Mobile Cooler Fan', 'frostcore-mobile-cooler-fan', '5', 'Compact smartphone cooling fan designed to reduce heat during long gaming sessions and maintain smoother performance.', '1782370579_Service_Image.png', '', 'PRODUCT', 'ACTIVE', '1782370579'),
(319, 'Vortex X7 Gaming Headset', 'vortex-x7-gaming-headset', '6', 'Wired over-ear gaming headphones with immersive stereo sound, noise-isolating earcups, and an adjustable microphone.', '1782370609_Service_Image.png', '', 'PRODUCT', 'ACTIVE', '1782370609'),
(320, '1500', '1', '334', '<div>Preparing the correct documents is one of the most important parts of applying for MBBS abroad. Missing or incorrect documents can delay admission, visa processing, or university registration. Therefore, students should begin collecting and verifying all required documents well before application deadlines.</div><div><br></div><div>Commonly required documents include a valid passport, Class 10 and 12 mark sheets, passing certificates, passport-sized photographs, birth certificate, medical fitness certificate, and completed university application forms. Some universities may also request additional academic transcripts, English proficiency certificates, or entrance examination details depending on their admission policies.</div><div><br></div><div>Students must also prepare supporting documents required for visa applications, including admission letters, invitation letters, financial proof, travel insurance, and accommodation details. Certain countries require document translation, notarization, Apostille, attestation, or legalization before submission. Understanding these requirements in advance helps avoid unnecessary delays.</div><div><br></div><div>All documents should be carefully reviewed to ensure consistency in names, dates of birth, passport details, and educational information. Maintaining both physical and digital copies is highly recommended throughout the admission journey.</div><div><br></div><div>Professional counseling agencies often assist students with document verification, translation, legal authentication, and application preparation, ensuring every requirement is completed accurately. Their guidance reduces errors and speeds up the admission process.</div><div><br></div><div>By preparing documents systematically and following university guidelines carefully, students can complete their MBBS admission process smoothly and confidently, allowing them to focus on beginning their exciting journey toward becoming successful medical professionals.</div>', '1784634017_QR.png', '', 'QR', 'ACTIVE', '1782370877'),
(321, 'WORLD777', 'world777', '4', 'https://www.lipsum.com/', '1787650428_Book.jpeg', '', 'BOOK', 'ACTIVE', '1782371248'),
(322, 'LOTUS365', 'lotus365', '3', 'https://www.lotus365s.id', '1787650352_Book.jpeg', '', 'BOOK', 'ACTIVE', '1782371318'),
(323, 'DREAM 444', 'dream-444', '2', 'https://dream444.net', '1787650208_Book.jpeg', '', 'BOOK', 'ACTIVE', '1782371378'),
(324, 'SKYEXCHANGE', 'skyexchange', '1', 'https://www.skyexch.biz', '1787649794_Book.jpg', '', 'BOOK', 'ACTIVE', '1782371456'),
(325, '910003874125', '910003874125', '23', 'Sample Bank', '', '', 'BANK', 'ACTIVE', '1782371544'),
(326, '910003874555', '910003874555', '23', 'Test Bank', '', '', 'BANK', 'ACTIVE', '1782371605'),
(327, '912563874125', '912563874125', '23', 'Horizon National Bank\nKavya Patel\n912563874125\nHNBK0001357\nCurrent', '', '', 'BANK', 'ACTIVE', '1782540632'),
(328, '325874169852', '325874169852', '1', 'Global Secure Bank\r\nAman Singh\r\n325874169852\r\nGSBK0002468\r\nSavings', '', '', 'BANK', 'ACTIVE', '1782540684'),
(329, '698745123658', '698745123658', '1', 'Zenith Commercial Bank\r\nNeha Gupta\r\n698745123658\r\nZCBK0008765\r\nCurrent', '', '', 'BANK', 'ACTIVE', '1782540734'),
(330, '784512369874', '784512369874', '1', 'Prime Capital Bank\nArjun Mehta\n784512369874\nPCBK0004321\nSavings', '', '', 'BANK', 'ACTIVE', '1782541036'),
(331, '563214789650', '563214789650', '1', 'Unity Finance Bank\r\nPriya Verma\r\n563214789650\r\nUFBK0005678\r\nCurrent', '', 'ADMIN-RECEIVABLE', 'BANK', 'ACTIVE', '1782541119'),
(332, 'Step-by-Step MBBS Admission Process for Indian Students', 'step-by-step-mbbs-admission-process-for-indian-students', '10', '<div>Pursuing an MBBS degree abroad is a dream for thousands of Indian students, and understanding the complete admission process is essential for a smooth and successful journey. With proper planning and expert guidance, students can avoid unnecessary delays and secure admission to internationally recognized medical universities with confidence.</div><div><br></div><div>The first step is to assess your academic eligibility and qualify NEET, if required under the applicable regulations for studying medicine abroad. After evaluating your academic profile, the next step is selecting the right country and university based on factors such as recognition, tuition fees, clinical training, infrastructure, hostel facilities, living expenses, and future career opportunities.</div><div><br></div><div>Once the university is selected, students complete the admission application and submit the required documents, including academic certificates, passport, photographs, and other supporting paperwork. After document verification, the university reviews the application and issues an official admission letter upon successful acceptance.</div><div><br></div><div>The next stage includes visa documentation, invitation letter processing, medical insurance, and preparation of all travel-related documents. Students should carefully follow the embassy requirements and submit accurate information during the visa application process. Once the visa is approved, travel arrangements, hostel booking, and pre-departure orientation are completed.</div><div><br></div><div>Upon arrival, students complete university registration, hostel check-in, and orientation sessions before beginning their medical education. Throughout the academic journey, students benefit from continuous guidance, academic support, and assistance whenever required.</div><div><br></div><div>At Medico Admission Hub, we provide complete end-to-end support, including career counseling, university selection, admission, documentation, visa assistance, travel planning, and post-arrival services. Our experienced team ensures that every step is completed professionally, allowing students to focus on achieving their dream of becoming successful doctors.</div>', '1782541174_Blog_Image.webp', '', 'BLOG', 'ACTIVE', '1782541174'),
(333, 'Why Medico Admission Hub is Your Trusted Partner for MBBS Abroad', 'why-medico-admission-hub-is-your-trusted-partner-for-mbbs-abroad', '11', '<div>Choosing the right education consultancy is just as important as choosing the right medical university. At Medico Admission Hub, we have been helping aspiring doctors achieve their dreams for over 15 years, providing reliable guidance, transparent counseling, and complete admission support for MBBS abroad. Our commitment to student success has earned the trust of thousands of students and parents across India.</div><div><br></div><div>We specialize in admissions to internationally recognized medical universities in Georgia, Russia, Kazakhstan, Uzbekistan, Kyrgyzstan, Bangladesh, Nepal, and Tajikistan. Our experienced counselors understand that every student has unique academic goals and financial requirements. That\'s why we provide personalized guidance to help students select the most suitable university based on their profile, career aspirations, and budget.</div><div><br></div><div>Our services go beyond admission. We assist students with university selection, application submission, document verification, translation, visa invitation, visa processing, travel planning, airport assistance, hostel accommodation, and continuous support throughout their medical education. From the first counseling session until students successfully begin their university life abroad, our team remains committed to providing professional assistance at every stage.</div><div><br></div><div>Transparency, honesty, and student satisfaction are the core values of Medico Admission Hub. We ensure that students receive accurate information about tuition fees, living expenses, university recognition, scholarship opportunities, and admission requirements without hidden charges or misleading promises.</div><div><br></div><div>Our strong relationships with leading international medical universities, experienced counseling team, and student-first approach make us one of India\'s trusted names in medical education consultancy. We believe every aspiring doctor deserves the best guidance to build a successful future.</div><div><br></div><div>If your dream is to study MBBS abroad, Medico Admission Hub is ready to help you every step of the way. Let our experience, dedication, and expertise guide you toward a rewarding medical career and a brighter future.</div>', '1782541216_Blog_Image.webp', '', 'BLOG', 'ACTIVE', '1782541216'),
(334, '458712369854', '458712369854', '1', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', 'BANK', 'ACTIVE', '1784636965');

-- --------------------------------------------------------

--
-- Table structure for table `otps`
--

CREATE TABLE `otps` (
  `id` int(11) NOT NULL,
  `phone` varchar(50) NOT NULL,
  `otp` varchar(20) NOT NULL,
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pay_to_admin`
--

CREATE TABLE `pay_to_admin` (
  `id` int(11) NOT NULL,
  `agency_id` varchar(20) NOT NULL,
  `amount` varchar(50) NOT NULL,
  `transaction_id` varchar(150) NOT NULL,
  `bank_id` varchar(20) NOT NULL,
  `bank_name` varchar(150) NOT NULL,
  `bank_slag` varchar(150) NOT NULL,
  `image` text NOT NULL,
  `remark` text NOT NULL,
  `admin_bank_id` varchar(20) NOT NULL,
  `admin_bank_name` varchar(150) NOT NULL,
  `admin_bank_slag` varchar(150) NOT NULL,
  `stage_status` varchar(20) NOT NULL,
  `read_status` varchar(20) NOT NULL DEFAULT '''PENDING''',
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pricerange`
--

CREATE TABLE `pricerange` (
  `id` int(11) NOT NULL,
  `price_start` varchar(20) NOT NULL,
  `price_end` varchar(20) NOT NULL,
  `show_status` varchar(20) NOT NULL,
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pricerange`
--

INSERT INTO `pricerange` (`id`, `price_start`, `price_end`, `show_status`, `date_ts`) VALUES
(1, '1', '100', 'ACTIVE', '1784702854'),
(2, '101', '1000', 'ACTIVE', '1784702892'),
(3, '1001', '10000', 'ACTIVE', '1784702915');

-- --------------------------------------------------------

--
-- Table structure for table `profit_loss`
--

CREATE TABLE `profit_loss` (
  `id` int(11) NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `subscription_id` varchar(20) NOT NULL,
  `book_id` varchar(50) NOT NULL,
  `username` varchar(150) NOT NULL,
  `profit` varchar(50) NOT NULL,
  `loss` varchar(50) NOT NULL,
  `start_date` varchar(20) NOT NULL,
  `end_date` varchar(20) NOT NULL,
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `profit_loss`
--

INSERT INTO `profit_loss` (`id`, `user_id`, `subscription_id`, `book_id`, `username`, `profit`, `loss`, `start_date`, `end_date`, `date_ts`) VALUES
(5, '22', '1', '324', 'USA-1948', '0.00', '50.00', '2026-08-02', '2026-08-07', '1786360135'),
(6, '24', '3', '324', 'AB123', '100.00', '0.00', '2026-08-02', '2026-08-07', '1786360135');

-- --------------------------------------------------------

--
-- Table structure for table `qrcode`
--

CREATE TABLE `qrcode` (
  `id` int(11) NOT NULL,
  `range_id` varchar(20) NOT NULL,
  `emp_id` varchar(20) NOT NULL,
  `bank_id` varchar(20) NOT NULL,
  `image` text NOT NULL,
  `show_status` varchar(20) NOT NULL,
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `qrcode`
--

INSERT INTO `qrcode` (`id`, `range_id`, `emp_id`, `bank_id`, `image`, `show_status`, `date_ts`) VALUES
(1, '1', '1', '334', '1784640233_QR.png', 'ACTIVE', '1784640233'),
(2, '1', '1', '331', '1784707744_QR.png', 'INACTIVE', '1784707744'),
(3, '1', '1', '330', '1784707775_QR.png', 'INACTIVE', '1784707775'),
(4, '3', '23', '327', '1785149209_QR.png', 'ACTIVE', '1785149209'),
(5, '2', '23', '326', '1785149229_QR.png', 'ACTIVE', '1785149229');

-- --------------------------------------------------------

--
-- Table structure for table `recharge`
--

CREATE TABLE `recharge` (
  `id` int(11) NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `qr_id` varchar(20) NOT NULL,
  `range_id` varchar(20) NOT NULL,
  `amount` varchar(20) NOT NULL,
  `stage_status` varchar(20) NOT NULL,
  `emp_id` varchar(20) NOT NULL,
  `book_id` varchar(20) NOT NULL,
  `subscription_id` varchar(20) NOT NULL,
  `transection_id` varchar(150) NOT NULL,
  `bank_id` varchar(20) NOT NULL,
  `bank_name` varchar(150) NOT NULL,
  `bank_slag` varchar(150) NOT NULL,
  `bank_details` text NOT NULL,
  `remark` text NOT NULL,
  `employee_remark` varchar(150) NOT NULL,
  `image` text NOT NULL,
  `invoice` text NOT NULL,
  `employee_read_status` varchar(20) NOT NULL,
  `agency_read_status` varchar(20) NOT NULL,
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recharge`
--

INSERT INTO `recharge` (`id`, `user_id`, `qr_id`, `range_id`, `amount`, `stage_status`, `emp_id`, `book_id`, `subscription_id`, `transection_id`, `bank_id`, `bank_name`, `bank_slag`, `bank_details`, `remark`, `employee_remark`, `image`, `invoice`, `employee_read_status`, `agency_read_status`, `date_ts`) VALUES
(32, '24', '1', '1', '100', 'AGENCY-PENDING', '1', '323', '6', '1234455666987', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787208867_Recharge_Image.jpeg', '', 'PENDING', 'PENDING', '1787208867'),
(33, '24', '1', '1', '100', 'AGENCY-PENDING', '1', '323', '6', '1233344445435', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '', '', 'PENDING', 'PENDING', '1787208882'),
(34, '24', '1', '1', '100', 'EMPLOYEE-PENDING', '1', '323', '6', '891852312135', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787209444_Recharge_Image.jpeg', '', 'READ', 'READ', '1787209444'),
(35, '24', '1', '1', '100', 'AGENCY-PENDING', '1', '323', '6', '89185231322', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787209686_Recharge_Image.jpeg', '', 'PENDING', 'PENDING', '1787209686'),
(36, '24', '1', '1', '100', 'EMPLOYEE-PENDING', '1', '309', '7', '87765512334', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787210274_Recharge_Image.jpeg', '', 'READ', 'READ', '1787210274'),
(37, '24', '5', '2', '102', 'EMPLOYEE-DONE', '23', '324', '3', '123456785412', '326', '910003874555', '910003874555', 'Test Bank', 'Agency Done', 'Recharge Successfully Done!', '1787210476_Recharge_Image.jpeg', 'Invoice_1787210476_37.pdf', 'READ', 'READ', '1787210476'),
(38, '24', '5', '2', '102', 'EMPLOYEE-DONE', '23', '324', '3', '123456785412', '326', '910003874555', '910003874555', 'Test Bank', 'Agency Done', 'Recharge Done', '1787211157_Recharge_Image.webp', 'Invoice_1787211157_38.pdf', 'READ', 'READ', '1787211157'),
(39, '24', '5', '2', '103', 'EMPLOYEE-DONE', '23', '324', '3', '741085209630', '326', '910003874555', '910003874555', 'Test Bank', 'Agency Done', 'Employee Done Recharge', '1787212191_Recharge_Image.jpeg', 'Invoice_1787212191_39.pdf', 'READ', 'READ', '1787212191'),
(40, '24', '5', '2', '102', 'AGENCY-PENDING', '23', '324', '3', '123456785014', '326', '910003874555', '910003874555', 'Test Bank', '', '', '1787224537_Recharge_Image.jpeg', '', 'PENDING', 'READ', '1787224537'),
(41, '24', '1', '1', '100', 'EMPLOYEE-PENDING', '1', '322', '4', '1234567890', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787650579_Recharge_Image.png', '', 'READ', 'READ', '1787650579'),
(42, '24', '1', '1', '100', 'EMPLOYEE-PENDING', '1', '324', '3', '1234567890', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787666090_Recharge_Image.jpeg', '', 'READ', 'READ', '1787666090'),
(43, '24', '5', '2', '500', 'AGENCY-PENDING', '23', '324', '3', '123456789875', '326', '910003874555', '910003874555', 'Test Bank', '', '', '1787666109_Recharge_Image.jpeg', '', 'PENDING', 'READ', '1787666109'),
(44, '24', '1', '1', '100', 'EMPLOYEE-PENDING', '1', '324', '3', '0987654321', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787667843_Recharge_Image.png', '', 'READ', 'READ', '1787667843'),
(45, '22', '1', '1', '100', 'AGENCY-PENDING', '1', '324', '1', '123456789012', '334', '458712369854', '458712369854', 'National Trust Bank\r\nRahul Sharma\r\nNTBK0001234\r\nSavings', '', '', '1787668698_Recharge_Image.png', '', 'PENDING', 'PENDING', '1787668698');

-- --------------------------------------------------------

--
-- Table structure for table `site_stng`
--

CREATE TABLE `site_stng` (
  `id` int(11) NOT NULL,
  `heading` varchar(100) NOT NULL,
  `tag_line` text NOT NULL,
  `meta` text NOT NULL,
  `logo` text NOT NULL,
  `fevicon` text NOT NULL,
  `white_logo` text NOT NULL,
  `small_logo` text NOT NULL,
  `address` text NOT NULL,
  `embed_map` text NOT NULL,
  `video_link` text NOT NULL,
  `email` varchar(100) NOT NULL,
  `mobile` varchar(100) NOT NULL,
  `whatsapp` text NOT NULL,
  `land_no` varchar(100) NOT NULL,
  `facebook` text NOT NULL,
  `instagram` text NOT NULL,
  `twitter` text NOT NULL,
  `youtube` text NOT NULL,
  `notice` text NOT NULL,
  `sms_key` varchar(100) NOT NULL,
  `sms_sender` text NOT NULL,
  `pay_key` varchar(100) NOT NULL,
  `pay_code` varchar(100) NOT NULL,
  `count_1` varchar(100) NOT NULL,
  `count_2` varchar(100) NOT NULL,
  `count_3` varchar(100) NOT NULL,
  `count_4` varchar(100) NOT NULL,
  `theme_mode` varchar(10) NOT NULL DEFAULT 'dark',
  `theme_primary` varchar(20) NOT NULL DEFAULT '#8b5cf6',
  `theme_secondary` varchar(20) NOT NULL DEFAULT '#6366f1',
  `theme_bg` varchar(20) NOT NULL DEFAULT '#0b071e',
  `theme_card` varchar(20) NOT NULL DEFAULT '#161333',
  `theme_text` varchar(20) NOT NULL DEFAULT '#f8fafc',
  `date` date DEFAULT NULL,
  `time` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `site_stng`
--

INSERT INTO `site_stng` (`id`, `heading`, `tag_line`, `meta`, `logo`, `fevicon`, `white_logo`, `small_logo`, `address`, `embed_map`, `video_link`, `email`, `mobile`, `whatsapp`, `land_no`, `facebook`, `instagram`, `twitter`, `youtube`, `notice`, `sms_key`, `sms_sender`, `pay_key`, `pay_code`, `count_1`, `count_2`, `count_3`, `count_4`, `theme_mode`, `theme_primary`, `theme_secondary`, `theme_bg`, `theme_card`, `theme_text`, `date`, `time`) VALUES
(1, 'Office Manager', 'Office Manager is an all-in-one CRM designed to simplify business operations by managing customers, employees, leads, tasks, inventory, invoices, reports, and daily workflows through a secure, efficient, and user-friendly platform.', 'Office Manager', '1784194336_Logo_photo.png', '1784194336_fevicon_photo.png', '1784194371_white_logo_photo.png', '1784194371_small_logo_photo.png', 'Kolkata, West Bengal, India - 700000', '', '', 'officemanager@gmail.com', '+91 9000000000', '919000000000', '', 'https://www.facebook.com/share/1ArqnZKewV/', 'https://www.instagram.com/myspace_planner/', 'https://www.threads.com/@myspace_planner', 'https://pin.it/EU9sTqiqs', '', '2vR1Xs8ny4OtlICyba82eyl__n4dzJETu7zRLnqkVSs', '', '', '', '0', '0', '0', '0', 'dark', '#8b5cf6', '#6366f1', '#0b071e', '#161333', '#f8fafc', '2026-07-16', '03:54:57');

-- --------------------------------------------------------

--
-- Table structure for table `subscription`
--

CREATE TABLE `subscription` (
  `id` int(11) NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `book_id` varchar(20) NOT NULL,
  `emp_id` varchar(20) NOT NULL,
  `username` varchar(20) NOT NULL,
  `username_slag` varchar(150) NOT NULL,
  `password` varchar(20) NOT NULL,
  `stage_status` varchar(20) NOT NULL,
  `read_status` varchar(20) NOT NULL,
  `show_status` varchar(20) NOT NULL,
  `user_under` varchar(20) NOT NULL,
  `date_ts` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subscription`
--

INSERT INTO `subscription` (`id`, `user_id`, `book_id`, `emp_id`, `username`, `username_slag`, `password`, `stage_status`, `read_status`, `show_status`, `user_under`, `date_ts`) VALUES
(1, '22', '324', '1', 'USA-1948', 'usa-1948', '12345', 'DONE', 'READ', 'ACTIVE', 'ADMIN', '1784719824'),
(3, '24', '324', '23', 'AB123', 'ab123', '12345', 'DONE', 'READ', 'ACTIVE', 'AGENCY', '1785146851'),
(4, '24', '322', '23', '', '', '', 'PENDING', 'PENDING', 'ACTIVE', 'AGENCY', '1787144946'),
(5, '24', '310', '23', '', '', '', 'PENDING', 'PENDING', 'ACTIVE', 'AGENCY', '1787144990'),
(6, '24', '323', '23', '', '', '', 'PENDING', 'PENDING', 'ACTIVE', 'AGENCY', '1787145382'),
(7, '24', '309', '23', '', '', '', 'PENDING', 'PENDING', 'ACTIVE', 'AGENCY', '1787210255'),
(8, '24', '321', '23', '', '', '', 'PENDING', 'PENDING', 'ACTIVE', 'AGENCY', '1787662581'),
(9, '22', '323', '1', '', '', '', 'PENDING', 'PENDING', 'ACTIVE', 'ADMIN', '1787665440');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` text NOT NULL,
  `mob` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  `img` text NOT NULL,
  `agency_id` varchar(20) NOT NULL,
  `agency_unq_id` varchar(20) NOT NULL,
  `profit_loss_status` varchar(20) NOT NULL,
  `collect_limit` varchar(50) NOT NULL,
  `available_amount` varchar(20) NOT NULL,
  `read_status` varchar(20) NOT NULL,
  `verification` varchar(10) NOT NULL,
  `type` varchar(100) NOT NULL,
  `show_status` varchar(100) NOT NULL,
  `date` varchar(50) NOT NULL,
  `time` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `mob`, `email`, `password`, `img`, `agency_id`, `agency_unq_id`, `profit_loss_status`, `collect_limit`, `available_amount`, `read_status`, `verification`, `type`, `show_status`, `date`, `time`) VALUES
(1, 'Admin', '1234567890', 'admin@gmail.com', '12345', '', '', 'ADMIN-1', 'ACTIVE', '99999999', '', '', '', 'ADMIN', 'ACTIVE', '2023-07-21', '11:57:38'),
(2, 'Employee', '1234567890', 'employee@gmail.com', '12345', '', '', '', '', '', '', '', '', 'EMPLOYEE', 'ACTIVE', '2023-07-21', '11:57:38'),
(22, 'Jhon Smith', '9000000002', 'user@gmail.com', '12345', '1784369535_User_Image.png', '1', '', '', '', '', 'READ', 'PENDING', 'USER', 'ACTIVE', '2026-07-18', '02:53:41pm'),
(23, 'Ritdz 4k', '9000000000', 'agency@gmail.com', '12345', '1784376403_Agency.jpg', '', 'AGENCY-23', 'ACTIVE', '5000', '', '', '', 'AGENCY', 'ACTIVE', '2026-07-18', ''),
(24, 'Test User', '9000000055', 'sample@gmail.com', '12345', '', '23', '', '', '', '', 'READ', 'DONE', 'USER', 'ACTIVE', '2026-07-27', '01:31:17pm');

-- --------------------------------------------------------

--
-- Table structure for table `user_payment_accounts`
--

CREATE TABLE `user_payment_accounts` (
  `id` int(11) NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `account_name` varchar(150) NOT NULL,
  `account_no` varchar(150) NOT NULL,
  `ifsc_code` varchar(150) NOT NULL,
  `bank_name` varchar(150) NOT NULL,
  `upi_id` varchar(150) NOT NULL,
  `image` text NOT NULL,
  `stage_status` varchar(20) NOT NULL,
  `read_status` varchar(20) NOT NULL,
  `date_ts` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_payment_accounts`
--

INSERT INTO `user_payment_accounts` (`id`, `user_id`, `account_name`, `account_no`, `ifsc_code`, `bank_name`, `upi_id`, `image`, `stage_status`, `read_status`, `date_ts`) VALUES
(1, '24', 'LOREM IPSUM', '9876543210', 'SBIN000123', 'STATE BANK OF INDIA', 'loremipsum@ok.sbi', '1788160447_Payment_Acc_Image.png', 'EMPLOYEE-APPROVE', 'READ', '1788160527');

-- --------------------------------------------------------

--
-- Table structure for table `withdrawal`
--

CREATE TABLE `withdrawal` (
  `id` int(11) NOT NULL,
  `user_id` varchar(20) NOT NULL,
  `book_id` varchar(20) NOT NULL,
  `amount` varchar(20) NOT NULL,
  `user_ac_holder_name` varchar(150) NOT NULL,
  `user_ac_number` varchar(150) NOT NULL,
  `user_bank_name` varchar(150) NOT NULL,
  `user_bank_ifsc` varchar(50) NOT NULL,
  `user_upi_id` varchar(150) NOT NULL,
  `transaction_id` varchar(20) NOT NULL,
  `agency_id` varchar(20) NOT NULL,
  `stage_status` varchar(20) NOT NULL,
  `employee_read_status` varchar(20) NOT NULL,
  `agency_read_status` varchar(20) NOT NULL,
  `bank_id` varchar(150) NOT NULL,
  `bank_name` varchar(150) NOT NULL,
  `bank_slag` varchar(150) NOT NULL,
  `emp_agency_image` text NOT NULL,
  `image` text NOT NULL,
  `deatil` text NOT NULL,
  `remark` text NOT NULL,
  `date_ts` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `agency_cash_book`
--
ALTER TABLE `agency_cash_book`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cmstable`
--
ALTER TABLE `cmstable`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contact`
--
ALTER TABLE `contact`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `expense`
--
ALTER TABLE `expense`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `expense_heads`
--
ALTER TABLE `expense_heads`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `features`
--
ALTER TABLE `features`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `otps`
--
ALTER TABLE `otps`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pay_to_admin`
--
ALTER TABLE `pay_to_admin`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pricerange`
--
ALTER TABLE `pricerange`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `profit_loss`
--
ALTER TABLE `profit_loss`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `qrcode`
--
ALTER TABLE `qrcode`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `recharge`
--
ALTER TABLE `recharge`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `site_stng`
--
ALTER TABLE `site_stng`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `subscription`
--
ALTER TABLE `subscription`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_payment_accounts`
--
ALTER TABLE `user_payment_accounts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `withdrawal`
--
ALTER TABLE `withdrawal`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `agency_cash_book`
--
ALTER TABLE `agency_cash_book`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `cmstable`
--
ALTER TABLE `cmstable`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=183;

--
-- AUTO_INCREMENT for table `contact`
--
ALTER TABLE `contact`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=91;

--
-- AUTO_INCREMENT for table `expense`
--
ALTER TABLE `expense`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `expense_heads`
--
ALTER TABLE `expense_heads`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `features`
--
ALTER TABLE `features`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=335;

--
-- AUTO_INCREMENT for table `otps`
--
ALTER TABLE `otps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `pay_to_admin`
--
ALTER TABLE `pay_to_admin`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `pricerange`
--
ALTER TABLE `pricerange`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `profit_loss`
--
ALTER TABLE `profit_loss`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `qrcode`
--
ALTER TABLE `qrcode`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `recharge`
--
ALTER TABLE `recharge`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `site_stng`
--
ALTER TABLE `site_stng`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `subscription`
--
ALTER TABLE `subscription`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `user_payment_accounts`
--
ALTER TABLE `user_payment_accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `withdrawal`
--
ALTER TABLE `withdrawal`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
