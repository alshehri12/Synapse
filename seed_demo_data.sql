-- Seed demo data for Synapse (Supabase)
-- Themes: Mobile app for car fixing, Pizza restaurant project

-- NOTE: Replace these UUIDs with actual auth.users IDs in your project if needed
-- For quick demo, insert into public.users directly using auth.uid()-less policy

-- Demo users
insert into public.users (id, email, username, bio, skills, interests)
values
  ('11111111-1111-1111-1111-111111111111', 'ahmed@demo.com', 'AhmedMechanic', 'Car diagnostics and mobile apps enthusiast', '{Swift, iOS, Mechanics}', '{Automotive, MobileApp}'),
  ('22222222-2222-2222-2222-222222222222', 'sara@demo.com', 'SaraPizza', 'Food lover and operations guru', '{Swift, PM}', '{Food, Operations}'),
  ('33333333-3333-3333-3333-333333333333', 'mohammed@demo.com', 'MoDev', 'Full-stack iOS developer', '{Swift, Supabase}', '{Startups, Productivity}');

-- Ideas
insert into public.idea_sparks (id, author_id, author_username, title, description, tags, is_public, status, likes, comments)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'AhmedMechanic',
   'Mobile App for Car Fixing',
   'On-demand app to book car diagnostics, track repairs, and chat with mechanics.',
   '{MobileApp,Automotive,OnDemand}', true, 'sparking', 4, 2),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'SaraPizza',
   'Pizza Restaurant Project',
   'Digital transformation for local pizza place: ordering, loyalty, and operations.',
   '{Food,Restaurant,Delivery}', true, 'incubating', 2, 1);

-- Pods (projects)
insert into public.pods (id, idea_id, name, description, creator_id, is_public, status)
values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'CarFix Mobile', 'iOS app for car services booking and tracking', '11111111-1111-1111-1111-111111111111', true, 'active'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'PizzaOps', 'Operations and ordering system for pizza restaurant', '22222222-2222-2222-2222-222222222222', true, 'planning');

-- Members
insert into public.pod_members (id, pod_id, user_id, username, role, permissions)
values
  ('e1e1e1e1-e1e1-4e1e-9e1e-e1e1e1e1e1e1', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'AhmedMechanic', 'Creator', '{admin,edit,view}'),
  ('e2e2e2e2-e2e2-4e2e-9e2e-e2e2e2e2e2e2', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'MoDev', 'Member', '{edit,view}'),
  ('e3e3e3e3-e3e3-4e3e-9e3e-e3e3e3e3e3e3', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '22222222-2222-2222-2222-222222222222', 'SaraPizza', 'Creator', '{admin,edit,view}');

-- Tasks for CarFix Mobile
insert into public.tasks (id, pod_id, title, description, assigned_to, assigned_to_username, status, priority)
values
  ('t1111111-1111-4111-8111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Design booking flow', 'Wireframes and UI states', '33333333-3333-3333-3333-333333333333', 'MoDev', 'in_progress', 'high'),
  ('t2222222-2222-4222-8222-222222222222', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Implement Supabase auth', 'Email + Google sign-in', '33333333-3333-3333-3333-333333333333', 'MoDev', 'todo', 'high'),
  ('t3333333-3333-4333-8333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Push to TestFlight', 'Prepare build and notes', '11111111-1111-1111-1111-111111111111', 'AhmedMechanic', 'completed', 'medium');

-- Tasks for PizzaOps
insert into public.tasks (id, pod_id, title, description, assigned_to, assigned_to_username, status, priority)
values
  ('t4444444-4444-4444-8444-444444444444', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Menu data model', 'Design tables and relations', '22222222-2222-2222-2222-222222222222', 'SaraPizza', 'todo', 'medium'),
  ('t5555555-5555-4555-8555-555555555555', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Loyalty points logic', 'Define accrual and redemption', null, null, 'todo', 'low');

-- Idea comments
insert into public.idea_comments (id, idea_id, author_id, author_username, content)
values
  ('cmt11111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'MoDev', 'Great scope! I can implement the booking view.'),
  ('cmt22222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'AhmedMechanic', 'Perfect, let us start with auth and DB first.'),
  ('cmt33333-3333-4333-8333-333333333333', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'SaraPizza', 'We need delivery zones and promotions.');

-- Likes
insert into public.idea_likes (id, idea_id, user_id)
values
  ('like1111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333'),
  ('like2222-2222-4222-8222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111');

-- Chat messages (basic)
insert into public.chat_messages (id, pod_id, sender_id, sender_username, content)
values
  ('msg11111-1111-4111-8111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'MoDev', 'I pushed the initial UI.'),
  ('msg22222-2222-4222-8222-222222222222', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'AhmedMechanic', 'Great, testing now.');


