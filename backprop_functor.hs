{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
{-# LANGUAGE LiberalTypeSynonyms #-}

data Learner aSet bSet pSet = Learner{
    implementer :: pSet -> aSet -> bSet,
    update :: pSet -> aSet -> bSet -> pSet,
    request :: pSet -> aSet -> bSet -> aSet
}

equivalenceLearners :: (qSet -> pSet) -> (pSet -> qSet) -> (Learner aSet bSet pSet) -> (Learner aSet bSet qSet)
equivalenceLearners f f_inv learner1 = Learner{implementer=(implementer learner1) . f,
                                         update=(\q_elem a_elem b_elem -> f_inv $ (update learner1) (f q_elem) a_elem b_elem),
                                         request=(request learner1) . f
                                        }

compose_learners_helper :: Learner aSet bSet pSet -> Learner bSet cSet qSet -> qSet -> pSet -> aSet -> cSet -> (qSet,pSet,aSet)
compose_learners_helper learner1 learner2 q_elem p_elem a_elem c_elem = ((update learner2) q_elem b_elem1 c_elem,
                                                                         (update learner1) p_elem a_elem ((request learner2) q_elem b_elem1 c_elem),
                                                                         (request learner1) p_elem a_elem ((request learner2) q_elem b_elem1 c_elem))
                                                                        where b_elem1=(implementer learner1) p_elem a_elem

reshuffled :: (a,b,c) -> ((b,a),c)
reshuffled (x,y,z) = ((y,x),z)

compose_learners :: Learner aSet bSet pSet -> Learner bSet cSet qSet -> Learner aSet cSet (pSet,qSet)
compose_learners learner1 learner2 = Learner{implementer=(\tup -> ((implementer learner2) (snd tup)) . ((implementer learner1) (fst tup))),
                                             update =(\tup a_elem c_elem -> fst . reshuffled $ compose_learners_helper learner1 learner2 (snd tup) (fst tup) a_elem c_elem),
                                             request=(\tup a_elem c_elem -> snd . reshuffled $ compose_learners_helper learner1 learner2 (snd tup) (fst tup) a_elem c_elem)
                                            }

monoidal_helper :: (a->b,c->d) -> (a,c) -> (b,d)
monoidal_helper (f,g) (x,y) = (f x,g y)

product_learners_helper :: Learner aSet bSet pSet -> Learner cSet dSet qSet -> pSet -> qSet -> aSet -> cSet -> bSet -> dSet -> (pSet,aSet,qSet,cSet)
product_learners_helper learner1 learner2 p_elem q_elem a_elem c_elem b_elem d_elem = ((update learner1) p_elem a_elem b_elem, (request learner1) p_elem a_elem b_elem,
                                                                                       (update learner2) q_elem c_elem d_elem, (request learner2) q_elem c_elem d_elem)

reshuffled2 :: (p,a,q,c) -> ((p,q),(a,c))
reshuffled2 (x,y,z,w) = ((x,z),(y,w))

product_learners :: Learner aSet bSet pSet -> Learner cSet dSet qSet -> Learner (aSet,cSet) (bSet,dSet) (pSet,qSet)
product_learners learner1 learner2 = Learner{implementer=(\tup -> monoidal_helper (implementer learner1 (fst tup),(implementer learner2) (snd tup))),
                                             update =(\params inputs outputs -> fst . reshuffled2 $ product_learners_helper learner1 learner2 (fst params) (snd params) (fst inputs) (snd inputs) (fst outputs) (snd outputs)),
                                             request=(\params inputs outputs -> snd . reshuffled2 $ product_learners_helper learner1 learner2 (fst params) (snd params) (fst inputs) (snd inputs) (fst outputs) (snd outputs))
                                            }